import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../helper/endpoint.dart';
import 'login_controller.dart';

class HomeController extends GetxController {
  var isLoading = true.obs;
  var totalPenerimaan = 0.0.obs;
  var totalPengeluaran = 0.0.obs;
  var saldo = 0.0.obs;

  var transaksiTerakhir = <Map<String, dynamic>>[].obs;
  var selectedMonth = 0.obs; // 0 = Semua Bulan, 1 = Januari, dst.
  var selectedJenis = RxInt(-1); // -1 = semua, 0 = penerimaan, 1 = pengeluaran

  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();

    // Auto-refresh saat user ubah filter
    ever(selectedMonth, (_) {
      fetchDashboardData();
    });

    ever(selectedJenis, (_) {
      // Tidak perlu fetch ulang ke server, karena filter hanya berdasarkan data lokal
      // Tapi bisa ditrigger refresh UI (misalnya via update())
      update();
    });
  }

  @override
  void onReady() {
    super.onReady();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      await GetStorage.init();

      isLoading.value = true;
      final _loginController = Get.find<LoginController>();
      final exptoken = await _loginController.getValidAccessToken();
      if (exptoken == null) {
        _loginController.refreshToken();
        return;
      }

      final token = box.read('token');
      final user = box.read('username') ?? '';

      final response = await http.get(
        Uri.parse(apiTransaksi),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'username': user,
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'];

        data.sort((a, b) {
          final dateA = DateTime.tryParse(a['tanggal'] ?? '') ?? DateTime(1900);
          final dateB = DateTime.tryParse(b['tanggal'] ?? '') ?? DateTime(1900);
          return dateB.compareTo(dateA);
        });

        transaksiTerakhir.value = List<Map<String, dynamic>>.from(data);

        totalPenerimaan.value = transaksiTerakhir
            .where((e) => e['status'] == 0)
            .fold(0.0, (sum, e) => sum + (e['nominal'] ?? 0.0));

        totalPengeluaran.value = transaksiTerakhir
            .where((e) => e['status'] == 1)
            .fold(0.0, (sum, e) => sum + (e['nominal'] ?? 0.0));

        saldo.value = totalPenerimaan.value - totalPengeluaran.value;
      } else {
        Get.snackbar("Error", "Gagal mengambil data: ${response.statusCode}");
      }
    } catch (e) {
      Get.snackbar("Exception", "Terjadi kesalahan: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Getter untuk data transaksi yang difilter berdasarkan bulan dan jenis
  List<Map<String, dynamic>> get filteredTransaksi {
    final month = selectedMonth.value;
    final jenis = selectedJenis.value;

    return transaksiTerakhir.where((trx) {
      final date = DateTime.tryParse(trx['tanggal'] ?? '');
      final status = trx['status'];

      final cocokBulan = (month == 0 || (date != null && date.month == month));
      final cocokJenis = (jenis == -1 || status == jenis);

      return cocokBulan && cocokJenis;
    }).toList();
  }

   
  /// Format currency ke format IDR
  String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return format.format(amount);
  }

  /// Format tanggal
  String formatTanggal(String tanggal) {
    try {
      final date = DateTime.parse(tanggal);
      final formatter = DateFormat('dd-MMM-yyyy', 'id_ID');
      return formatter.format(date);
    } catch (e) {
      print('💥 Exception saat format tanggal: $tanggal, error: $e');
      return tanggal;
    }
  }
}
