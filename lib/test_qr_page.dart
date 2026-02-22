import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TestQRPage extends StatelessWidget {
  const TestQRPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D1F1E),
        title: const Text("Test QR Code"),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "SCAN ME",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5D1F1E),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Use the 'Library' scanner to test",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5),
                  ],
                ),
                child: QrImageView(
                  data: "LIBRARY-ENTRY",
                  version: QrVersions.auto,
                  size: 250.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF5D1F1E),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              const Icon(Icons.info_outline, color: Colors.black26),
              const SizedBox(height: 8),
              const Text(
                "This is a sample QR code for 'LIBRARY-ENTRY'.\nScanning this will simulate entry into the library.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black38, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
