import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'qr_scanner_page.dart';
import 'library_seat_map_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  static const int totalSeats = 30;
  static const String validQr = "LIBRARY-ENTRY";

  // Real-time stream — no manual loadSeatCount needed
  final Stream<QuerySnapshot> _seatStream = FirebaseFirestore.instance
      .collection("library_logs")
      .where("status", isEqualTo: "checked_in")
      .snapshots();

  // ── QR scan entry point ───────────────────────────────────────────────────
  Future<void> processScan(String rawScanned) async {
    final scanned = rawScanned.trim();

    if (scanned.startsWith("ATTENDANCE:")) {
      await handleAttendanceScan(scanned);
      return;
    }

    if (scanned != validQr) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Invalid QR: \"$scanned\"")));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check already checked in
    final existingCheckin = await FirebaseFirestore.instance
        .collection("library_logs")
        .where("uid", isEqualTo: user.uid)
        .where("status", isEqualTo: "checked_in")
        .get();

    if (existingCheckin.docs.isNotEmpty) {
      if (!mounted) return;
      final logData = existingCheckin.docs.first.data();
      final existingSeat = logData["seatNumber"] ?? 1;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Already checked in — Seat $existingSeat")),
      );
      final logId = existingCheckin.docs.first.id;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LibrarySeatMapPage(existingLogId: logId),
        ),
      );
      return;
    }

    // Fetch student data
    final studentDoc = await FirebaseFirestore.instance
        .collection("students")
        .doc(user.uid)
        .get();

    if (!studentDoc.exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Student record not found")));
      return;
    }

    if (!mounted) return;

    // Navigate to seat selection — log creation happens after seat is picked
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibrarySeatMapPage(
          studentUid: user.uid,
          studentData: studentDoc.data(),
        ),
      ),
    );
  }

  Future<void> handleAttendanceScan(String scanned) async {
    final parts = scanned.split(":");
    if (parts.length < 5) return;

    final facultyUid = parts[1];
    final date = parts[4];

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final studentDoc = await FirebaseFirestore.instance
        .collection("students")
        .doc(user.uid)
        .get();

    if (!studentDoc.exists) return;
    final studentData = studentDoc.data()!;

    final existing = await FirebaseFirestore.instance
        .collection("attendance")
        .where("studentUid", isEqualTo: user.uid)
        .where("facultyUid", isEqualTo: facultyUid)
        .where("date", isEqualTo: date)
        .get();

    if (existing.docs.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance already marked for today!")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection("attendance").add({
      "studentUid": user.uid,
      "studentName": studentData["name"],
      "studentId": studentData["studentId"],
      "department": studentData["department"],
      "semester": studentData["semester"],
      "facultyUid": facultyUid,
      "subject": "GENERAL",
      "present": true,
      "date": date,
      "timestamp": FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    // Navigate to seat map after successful attendance marking
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LibrarySeatMapPage(studentUid: user.uid, studentData: studentData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F1EB),
      body: StreamBuilder<QuerySnapshot>(
        stream: _seatStream,
        builder: (context, snapshot) {
          final occupiedSeats = snapshot.hasData
              ? snapshot.data!.docs.length
              : 0;
          final availableSeats = (totalSeats - occupiedSeats).clamp(
            0,
            totalSeats,
          );
          final isFull = availableSeats <= 0;

          return SingleChildScrollView(
            child: Column(
              children: [
                header(),
                const SizedBox(height: 20),
                qrCard(isFull),
                const SizedBox(height: 20),
                seatInfoCard(occupiedSeats, availableSeats),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 40),
      decoration: const BoxDecoration(
        color: Color(0xFF5D1F1E),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(70),
          bottomRight: Radius.circular(70),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text(
            "Library",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget qrCard(bool isFull) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Icon(
            isFull ? Icons.block : Icons.qr_code_2,
            size: 50,
            color: isFull ? Colors.red : Colors.brown,
          ),
          const SizedBox(height: 10),
          Text(
            isFull ? "Library is Full" : "Scan QR to Check In",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isFull ? Colors.red : Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isFull
                ? "All $totalSeats seats are currently occupied. Please try again later."
                : "Scan the QR code at the library entrance to check in",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isFull ? Colors.red.shade300 : Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: isFull
                ? null
                : () async {
                    final scanned = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QRScannerPage()),
                    );
                    if (scanned != null) {
                      await processScan(scanned);
                    }
                  },
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: isFull ? Colors.grey.shade400 : const Color(0xFF5D1F1E),
                borderRadius: BorderRadius.circular(30),
              ),
              alignment: Alignment.center,
              child: Text(
                isFull ? "No Seats Available" : "Open Camera to Scan",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget seatInfoCard(int occupiedSeats, int availableSeats) {
    final percentage = totalSeats > 0 ? occupiedSeats / totalSeats : 0.0;
    final color = percentage >= 1.0
        ? Colors.red
        : percentage >= 0.7
        ? Colors.orange
        : Colors.green;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF5D1F1E),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.event_seat, color: Colors.white, size: 28),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  "Available: $availableSeats / $totalSeats seats",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$occupiedSeats occupied",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                "$availableSeats free",
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
