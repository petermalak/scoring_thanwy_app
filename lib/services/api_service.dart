import 'dart:convert';

import 'package:dio/dio.dart';

class ApiService {
  static Future<Map<String, dynamic>> sendQrData(String qrCode, String selectedValue) async {
    final dio = Dio();
    dio.options.headers['Content-Type'] = 'application/json';

    final data = {
      "qrCode": qrCode,
      "selectedValue": selectedValue,
      "timestamp": DateTime.now().toUtc().toIso8601String(),
    };

    const String url = 'https://scoring-thanwy-web-km5e.vercel.app/api/submit';

    try {
      final response = await dio.post(url, data: data);

      if (response.statusCode == 200) {
        // Ensure we return a Map
        return response.data is Map<String, dynamic>
            ? response.data
            : json.decode(response.data);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to send QR data: $e');
    }
  }
}