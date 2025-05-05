import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../helper/endpoint.dart';
import '../pages/dashboard_page.dart';

class LoginController extends GetxController {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
 
 var isLoading = false.obs;
  var obscurePassword = true.obs;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }
  
  final box = GetStorage();
Future<bool> refreshToken() async {
  final refreshToken = box.read('refreshToken');

  final response = await http.post(
    Uri.parse(apiRefresh),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'refreshToken': refreshToken}),
  );

  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    final newToken = body['token'];
    final newRefresh = body['refreshToken'];
    final expiresIn = body['expiresIn']; // asumsi dalam detik
    final now = DateTime.now();
    final expireAt = now.add(Duration(minutes: expiresIn)).millisecondsSinceEpoch;
 
    box.write('expires', expireAt);
    box.write('token', newToken);
    box.write('refreshToken', newRefresh);
    return true;
  }

  return false;
}
  Future<void> loginUser() async {
    isLoading.value = true;

    final url = Uri.parse(apiLogin); // Ganti IP

    final body = jsonEncode({
      "username": usernameController.text,
      "password": passwordController.text,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      isLoading.value = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final refreshToken = data['refreshToken'];     
        final expiresIn = data['expiresIn']; // asumsi dalam detik
        final username = usernameController.text;

        final now = DateTime.now();
       final expireAt = now.add(Duration(minutes: expiresIn)).millisecondsSinceEpoch;

        // Simpan token, expires dan username
        box.write('token', token);
         box.write('refreshToken', refreshToken);
        box.write('expires', expireAt);
        box.write('username', username);
        await _sendFcmTokenToServer();
        Get.offAll(() => DashboardPage());
      } else {
        Get.snackbar("Gagal", "Login gagal: ${response.body}",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white);
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Terjadi kesalahan: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
    }
  }
  // Kirim token FCM ke server
  Future<void> _sendFcmTokenToServer() async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    box.write('fcmtoken', fcmToken); // Simpan token FCM ke GetStorage
    if (fcmToken != null) {
      final url = Uri.parse(apiFCMToken); // API endpoint untuk mengirim token FCM ke server
      final body = jsonEncode({
        "username": box.read('username'), // Ambil username dari GetStorage
        "token_fcm": fcmToken,
      });

      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: body,
        );

        if (response.statusCode == 200) {
          
        }  
      } catch (e) {
         
      }
    }  
  }


Future<String?> getValidAccessToken() async {
  await GetStorage.init();
  final expiryStr = await box.read('expires');
  final refreshToken = await box.read('refreshToken');
  final accessToken = await box.read('token');

  if (expiryStr == null || refreshToken == null || accessToken == null) return null;

   
  final expireDateTime = DateTime.fromMillisecondsSinceEpoch(expiryStr);

  // Cek apakah sekarang masih sebelum waktu kedaluwarsa (dengan grace period 10 detik)
  if (DateTime.now().isBefore(expireDateTime.subtract(Duration(seconds: 30)))) {
    return accessToken;
  }
  // Token expired, refresh
  final res = await http.post(
    Uri.parse(apiRefresh),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'refreshToken': refreshToken}),
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    final newToken = data['token'];
    final newRefresh = data['refreshToken'];
    final expiresIn = data['expiresIn'];
    final expireAt = DateTime.now().add(Duration(days: expiresIn)).millisecondsSinceEpoch;
    await box.write('token', newToken);
    await box.write('refreshToken', newRefresh);
    await box.write('expires', expireAt);

    return newToken;
  } 
  // Gagal refresh
  logout(); 
  return null;
}
  void logout() {
    box.erase(); // hapus semua
    Get.offAllNamed('/login');
  }

   
}
