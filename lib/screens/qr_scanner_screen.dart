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
  String selectedRating = "";
  late MobileScannerController cameraController;

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
      isCameraOn = false; // Automatically stop camera after successful scan
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Scanned: $code')),
    );

    await Future.delayed(const Duration(seconds: 1));
    setState(() => isProcessing = false);
  }

  void _submit() async {
    if (scanResult == null || selectedRating.isEmpty) return;

    final response = await ApiService.sendQrData(scanResult!, selectedRating);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response)),
    );

    setState(() {
      scanResult = null;
      selectedRating = "";
    });
  }

  void _startCamera() {
    setState(() {
      scanResult = null; // Reset scan result when starting new scan
      isCameraOn = true;
    });
    // Reinitialize the controller to ensure fresh state
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Code Scanner")),
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
                      child: const Center(child: Text("Camera is off")),
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
                  label: const Text("Start"),
                  onPressed: isCameraOn ? null : _startCamera,
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop_circle),
                  label: const Text("Stop"),
                  onPressed: !isCameraOn ? null : _stopCamera,
                ),
              ],
            ),
            if (scanResult != null) ...[
              const SizedBox(height: 20),
              Text("Scanned: $scanResult", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedRating.isEmpty ? null : selectedRating,
                decoration: const InputDecoration(labelText: "Select Rating (1-5)"),
                items: [1, 2, 3, 4, 5].map((num) {
                  return DropdownMenuItem(value: num.toString(), child: Text(num.toString()));
                }).toList(),
                onChanged: (value) => setState(() => selectedRating = value ?? ""),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: selectedRating.isNotEmpty ? _submit : null,
                child: const Text("Submit Score"),
              ),
            ]
          ],
        ),
      ),
    );
  }
}