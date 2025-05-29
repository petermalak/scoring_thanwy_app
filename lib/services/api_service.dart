import 'package:dio/dio.dart';

class ApiService {
  static Future<String> sendQrData(String qrCode, String selectedValue) async {
    final dio = Dio();

    // Setting headers
    dio.options.headers['Content-Type'] = 'application/json';

    // Create the request payload
    final data = {
      "qrCode": qrCode,
      "selectedValue": selectedValue,
      "timestamp": DateTime.now().toUtc().toIso8601String(),
    };

    const String url =
        'https://scoring-thanwy-web-km5e.vercel.app/api/submit';

    try {
      final response = await dio.post(url, data: data);

      if (response.statusCode == 200) {
        return 'Success: ${response.data}';
      } else {
        return 'Error ${response.statusCode}: ${response.statusMessage}';
      }
    } catch (e) {
      print('Error sending QR data: $e');
      return 'Failed to send QR data';
    }
  }
}
