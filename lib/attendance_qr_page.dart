import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

class AttendanceQRPage extends StatelessWidget {
  final String facultyUid;
  final String facultyName;
  final String subject;
  final String semester;

  const AttendanceQRPage({
    super.key,
    required this.facultyUid,
    required this.facultyName,
    required this.subject,
    required this.semester,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    // Unique data format for attendance scanning
    final qrData = "ATTENDANCE:$facultyUid:GENERAL:ALL:$dateStr";

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EB),
      appBar: AppBar(
        title: const Text("Session QR Code"),
        backgroundColor: const Color(0xFF5D1F1E),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_clock, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "LIVE SESSION",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Text(
                "General Attendance",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF5D1F1E)),
              ),
              Text(
                "All Semesters • $facultyName",
                style: const TextStyle(fontSize: 16, color: Colors.black45, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5D1F1E).withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 240.0,
                      gapless: false,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.circle,
                        color: Color(0xFF5D1F1E),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.circle,
                        color: Color(0xFF5D1F1E),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "STUDENTS: SCAN TO MARK PRESENT",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.black26,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "This QR code is valid for today's session only. Ensure students scan this within the classroom.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black38, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
