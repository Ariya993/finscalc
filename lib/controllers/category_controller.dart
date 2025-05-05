import 'dart:convert';
import 'package:finscalc/helper/endpoint.dart'; 
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

import 'login_controller.dart';

class KategoriController extends GetxController {
  var namaKategoriController = TextEditingController();
  final namaKategori = ''.obs;
  final isLoading = false.obs;
  final statusKategori = 0.obs;
  final box = GetStorage();
  final String apiUrl = apiCategory; // Ganti sesuai
 var categories = <Category>[].obs; // Store fetched categories
 @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }
  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;

      // // API URL
      // final url = Uri.parse(apiCategory);

      // // Set the headers, including the Authorization header
      // final headers = {
      //   'Authorization': 'Bearer ${box.read('token')}',
      //   'Content-Type': 'application/json',
      //   'username': box.read('username') ?? ''
      // };

      // // Make the API request
      // final response = await http.get(url, headers: headers);
      final _loginController = Get.find<LoginController>();
      final exptoken = await _loginController.getValidAccessToken();
      if (exptoken == null) {
        _loginController.refreshToken();
        return;
      }
      final response = await http.get(
        Uri.parse(apiCategory),
        headers: {
          'Authorization': 'Bearer ${box.read('token')}',
          'Content-Type': 'application/json',
          'username': box.read('username') ?? '',
        }
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        categories.value = (data as List)
            .map((categoryData) => Category.fromJson(categoryData))
            .toList();
      } else {
        // Handle error (e.g., unauthorized, not found)
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any errors that might occur during the fetch
      print('Error fetching categories: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitKategori() async {
    if (namaKategori.value.isEmpty) {
      Get.snackbar('Error', 'Nama kategori tidak boleh kosong');
      return;
    }

    isLoading.value = true;

    final token = box.read('token');
    final user = box.read('username') ?? '';

        final body = {
      'category': namaKategori.value,
      'user_created': user,
      'status': statusKategori.value,
      'date_created': DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar('Sukses', 'Kategori berhasil ditambahkan');
        namaKategori.value = '';
      } else {
        Get.snackbar('Gagal', 'Status: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan: $e');
    } finally {
      isLoading.value = false;
    }
  }
  @override
  void onClose() {
    // Dispose the controller to prevent memory leaks
    namaKategoriController.dispose();
    super.onClose();
  }
  
}
class Category {
  final int id;
  final String category;
  final int status;

  Category({required this.id, required this.category, required this.status});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      category: json['category'],
      status: json['status'],
    );
  }
}