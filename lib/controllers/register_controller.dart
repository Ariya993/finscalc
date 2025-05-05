import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../helper/endpoint.dart';

class RegisterController extends GetxController {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final namaController = TextEditingController();

  var isLoading = false.obs;

  Future<void> registerUser() async {
    isLoading.value = true;

    final url = Uri.parse(apiUser); // GANTI IP sesuai IP PC kamu

    final body = jsonEncode({
      "id": 0,
      "username": usernameController.text,
      "password": passwordController.text,
      "nama": namaController.text,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      isLoading.value = false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar("Sukses", "Register berhasil!",
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar("Error", "Gagal register: ${response.body}",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Exception", e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
