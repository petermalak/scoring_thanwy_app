import 'package:flutter/material.dart';
import 'screens/qr_scanner_screen.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Scoring',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'OpenSans'),
      ),
      home: QRScannerScreen(),
    );
  }
}