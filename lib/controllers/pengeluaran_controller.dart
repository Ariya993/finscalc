import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../helper/endpoint.dart';
import '../pages/pengeluaran_page.dart';
import 'login_controller.dart';

class PengeluaranController extends GetxController {
  final tanggalController = TextEditingController();
  final nominalController = TextEditingController();
  final deskripsiController = TextEditingController();
  var selectedCategory = 1.obs; // default id_category
  var selectedDate = DateTime.now().obs;
  var imageFile = Rxn<File>();

  final box = GetStorage();
 var pengeluaranList = <Map<String, dynamic>>[].obs;
  var filterKategori = 0.obs; // 0 = semua
  var filterTanggalMulai = Rxn<DateTime>();
  var filterTanggalSelesai = Rxn<DateTime>();


Future<File?> compressImage(File file) async {
  try {
    final dir = await getTemporaryDirectory();
    final targetPath = path.join(dir.path, 'compressed_${path.basename(file.path)}');

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 60,
    );

    if (result == null) return null;
 
    return File(result.path);
  } catch (e) {
    print("Error saat kompresi gambar: $e");
    return null;
  }
}
Future<void> updatePengeluaran(int id) async {
  final _loginController = Get.find<LoginController>();
  final exptoken = await _loginController.getValidAccessToken();
  if (exptoken == null) {
    _loginController.refreshToken();
    return;
  }



  final token = box.read('token');
  final username = box.read('username');

  final request = http.MultipartRequest(
    'PUT',
    Uri.parse('$apiTransaksi/$id'),
  );

  request.headers['Authorization'] = 'Bearer $token';
  request.fields['id'] = id.toString();
  request.fields['id_category'] = selectedCategory.value.toString();
  request.fields['tanggal'] = selectedDate.value.toIso8601String();
  request.fields['nominal'] = nominalController.text;
  request.fields['description'] = deskripsiController.text;
  request.fields['status'] = '0';
  request.fields['user_updated'] = username;
  request.fields['date_updated'] = DateTime.now().toIso8601String();

  if (imageFile.value != null) {
      final imageSizeInBytes = await imageFile.value!.length();
      final imageSizeInMB = imageSizeInBytes / (1024 * 1024);
      if (imageSizeInMB > 1) {
        Get.snackbar('Gagal', 'Ukuran file tidak boleh lebih dari 1 MB');
        return;
      }
    final compressedImage = await compressImage(imageFile.value!);
      if (compressedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'ImageFile',
          compressedImage.path,
        ));
      } 
  }

  final response = await request.send();
   final responseBody = await response.stream.bytesToString();
  if (response.statusCode == 200) {
    Get.snackbar('Sukses', 'Data berhasil diupdate',
        backgroundColor: Colors.green, colorText: Colors.white);
           await Future.delayed(Duration(seconds: 1));
             fetchPengeluaran(); 
              Get.to(() => PengeluaranPage());
      clearForm();
  
  } else if (response.statusCode == 400) {
      Get.snackbar('Error', 'Data tidak valid : $responseBody',
          backgroundColor: Colors.red, colorText: Colors.white);
    } else if (response.statusCode == 401) {
      Get.snackbar('Error', 'Unauthorized',
          backgroundColor: Colors.red, colorText: Colors.white);
    } else if (response.statusCode == 500) {
      Get.snackbar('Error', 'Server error',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
    else {
    Get.snackbar('Error', 'Gagal mengupdate data',
        backgroundColor: Colors.red[100], colorText: Colors.white);
  }
}

Future<void> deletePengeluaran(int id) async {
  final token = box.read('token');
  final response = await http.delete(
    Uri.parse('$apiTransaksi/$id'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 204) {
    Get.snackbar('Berhasil', 'Data berhasil dihapus',
        backgroundColor: Colors.green);
         await Future.delayed(Duration(seconds: 1));
    fetchPengeluaran(); 
              Get.to(() => PengeluaranPage());
      clearForm();
  } else {
    Get.snackbar('Gagal', 'Gagal menghapus data',
        backgroundColor: Colors.red);
         await Future.delayed(Duration(seconds: 1));
        fetchPengeluaran();
  }
}
void fetchPengeluaran() async {
    final _loginController = Get.find<LoginController>();
  final exptoken = await _loginController.getValidAccessToken();
  if (exptoken == null) {
    _loginController.refreshToken();
    return;
  }

    final token = box.read('token');
    final response = await http.get(
      Uri.parse(apiTransaksi),
      headers: {
        'Authorization': 'Bearer $token',
        'username': box.read('username') ?? '',
      },
    );

    if (response.statusCode == 200) {
    //  final List<dynamic> data = jsonDecode(response.body); ////kalo formatnya langsung json
       final jsonResponse = jsonDecode(response.body);
    final List<dynamic> dataList = jsonResponse['data'];
 
      pengeluaranList.value = dataList
          .where((item) => item['status'] == 1)
          .map((e) => e as Map<String, dynamic>)
          .toList()
            ..sort((a, b) =>
      DateTime.parse(b['tanggal']).compareTo(DateTime.parse(a['tanggal'])));
    }  
  }
List<Map<String, dynamic>> get filteredPengeluaran {
  return pengeluaranList.where((item) {
    // Filter status: hanya status = 1 (pengeluaran)
    if (item['status'] != 1) return false;

    // Filter kategori
    if (filterKategori.value != 0 && item['id_category'] != filterKategori.value) return false;

    // Filter tanggal
    final itemTanggal = DateTime.parse(item['tanggal']);
    if (filterTanggalMulai.value != null && itemTanggal.isBefore(filterTanggalMulai.value!)) return false;
    if (filterTanggalSelesai.value != null && itemTanggal.isAfter(filterTanggalSelesai.value!)) return false;

    return true;
  }).toList();
}


  void pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      imageFile.value = File(picked.path);
    }
  }

  Future<void> submitPengeluaran() async {
    final _loginController = Get.find<LoginController>();
    final exptoken = await _loginController.getValidAccessToken();
    if (exptoken == null) {
      _loginController.loginUser();
      return;
    }
    final token = box.read('token');
    final username = box.read('username');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(apiTransaksi),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['id_category'] = selectedCategory.value.toString();
    request.fields['tanggal'] = selectedDate.value.toIso8601String();
    request.fields['nominal'] = nominalController.text;
    request.fields['description'] = deskripsiController.text;
    request.fields['status'] = '1';
    request.fields['user_created'] = username;
    request.fields['date_created'] = DateTime.now().toIso8601String();

    if (imageFile.value != null) {
        final compressedImage = await compressImage(imageFile.value!);
      if (compressedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'ImageFile',
          compressedImage.path,
        ));
      }
      // request.files.add(await http.MultipartFile.fromPath(
      //   'ImageFile',
      //   imageFile.value!.path,
      // ));
    }

    final response = await request.send();
    if (response.statusCode == 201) {
      Get.snackbar('Sukses', 'Data berhasil disimpan');
      fetchPengeluaran(); 
              Get.to(() => PengeluaranPage());
      clearForm();
    } else {
      Get.snackbar('Error', 'Gagal menyimpan data');
    }
  }

  void clearForm() {
    nominalController.clear();
    deskripsiController.clear();
    imageFile.value = null;
    selectedDate.value = DateTime.now();
    selectedCategory.value = 1;
  }
@override
  void onInit() {
    super.onInit();
    fetchPengeluaran();
  }

  @override
  void onClose() {
    tanggalController.dispose();
    nominalController.dispose();
    deskripsiController.dispose();
    super.onClose();
  }
}
