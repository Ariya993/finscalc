import 'package:finscalc/helper/endpoint.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FCMController {
  // Fungsi untuk mengirimkan notifikasi FCM
  Future<void> sendFCMNotification(String deviceToken, String title, String message) async {
    try {
      // Data untuk dikirim ke API FCM
      final Map<String, String> data = {
        "device": deviceToken,
        "title": title,
        "message": message,
        "type": "new", // Tipe notifikasi
      };

      // Endpoint API
      final url = Uri.parse(apiSendFCM);

      // Mengirimkan request POST ke API
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      // Mengecek respon dari server
      if (response.statusCode == 200) { 
      }  
    } catch (e) {
      
    }
  }
}
