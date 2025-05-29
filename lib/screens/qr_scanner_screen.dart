import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool isProcessing = false;
  bool isFlashOn = false;
  bool isCameraOn = false;
  String? scanResult;
  String selectedScore = "";
  late MobileScannerController cameraController;
  Map<String, dynamic>? apiResponse;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (isProcessing || capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final code = barcode.rawValue;

    if (code == null || (scanResult != null && scanResult == code)) return;

    setState(() {
      isProcessing = true;
      scanResult = code;
      isCameraOn = false;
      apiResponse = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم مسح الكود: $code')),
    );

    await Future.delayed(const Duration(seconds: 1));
    setState(() => isProcessing = false);
  }

  void _submit() async {
    if (scanResult == null || selectedScore.isEmpty) return;

    setState(() => isProcessing = true);

    try {
      final response = await ApiService.sendQrData(scanResult!, selectedScore);

      // Check if response is already a Map
      if (response is Map<String, dynamic>) {
        setState(() {
          apiResponse = response;
        });
      }
      // If response needs parsing (e.g., from JSON string)
      else if (response is String) {
        try {
          final parsedResponse = json.decode(response as String) as Map<String, dynamic>;
          setState(() {
            apiResponse = parsedResponse;
          });
        } catch (e) {
          throw Exception('Failed to parse response: $e');
        }
      } else {
        throw Exception('Unexpected response type');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _startCamera() {
    setState(() {
      scanResult = null;
      isCameraOn = true;
    });
    cameraController = MobileScannerController();
  }

  void _stopCamera() {
    setState(() => isCameraOn = false);
    cameraController.dispose();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("مسح كود QR"),
        backgroundColor: const Color(0xFFf9d950),
      ),
      backgroundColor: const Color(0xFFf9f5e1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  if (isCameraOn)
                    MobileScanner(
                      controller: cameraController,
                      onDetect: _onDetect,
                    )
                  else
                    Container(
                      color: Colors.grey[300],
                      child: const Center(child: Text("الكاميرا مغلقة")),
                    ),
                  Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle_fill),
                  label: const Text("تشغيل"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFf9d950),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: isCameraOn ? null : _startCamera,
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop_circle),
                  label: const Text("إيقاف"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFf9d950),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: !isCameraOn ? null : _stopCamera,
                ),
              ],
            ),
            if (scanResult != null) ...[
              const SizedBox(height: 20),
              Text("تم مسح: $scanResult",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedScore.isEmpty ? null : selectedScore,
                decoration: InputDecoration(
                  labelText: "اختيار النقاط",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(
                    value: "50",
                    child: Row(
                      children: [
                        Icon(Icons.construction, color: Colors.yellow),
                        SizedBox(width: 8),
                        Text("حضور اول ١٠ دقايق = ٥٠ طوبة"),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: "25",
                    child: Row(
                      children: [
                        Icon(Icons.construction, color: Colors.yellow),
                        SizedBox(width: 8),
                        Text("حضور تاني ١٠ دقايق = ٢٥ طوبة"),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: "10",
                    child: Row(
                      children: [
                        Icon(Icons.construction, color: Colors.yellow),
                        SizedBox(width: 8),
                        Text("مشاركة في الموضوع = ١٠ طوبات"),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => selectedScore = value ?? ""),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: isProcessing ? null : selectedScore.isNotEmpty ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFf9d950),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isProcessing
                    ? const CircularProgressIndicator()
                    : const Text("تسجيل النقاط", style: TextStyle(fontSize: 16)),
              ),
            ],
            if (apiResponse != null) ...[
              const SizedBox(height: 20),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          "تم تسجيل النقاط بنجاح",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow("الاسم:", apiResponse!['userData']['name']),
                      _buildInfoRow("الفصل:", apiResponse!['userData']['class']),
                      _buildInfoRow("الفريق:", apiResponse!['userData']['team']),
                      const Divider(height: 30, thickness: 1),
                      _buildInfoRow("النقاط السابقة:",
                          "${apiResponse!['userData']['previousScore']} طوبة",
                          isBold: true),
                      _buildInfoRow("النقاط الجديدة:",
                          "${apiResponse!['userData']['newScore']} طوبة",
                          isBold: true),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          "تم إضافة ${int.parse(selectedScore)} طوبة",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}