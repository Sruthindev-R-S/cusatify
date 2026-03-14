import 'package:flutter/material.dart';
import 'main.dart';
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

  int occupiedSeats = 0;
  bool loadingSeats = true;

  @override
  void initState() {
    super.initState();
    loadSeatCount();
    // Listen for real-time changes
    supabase
        .from('library_logs')
        .stream(primaryKey: ['id'])
        .eq('status', 'checked_in')
        .listen((data) {
      if (mounted) {
        setState(() {
          occupiedSeats = data.length;
          loadingSeats = false;
        });
      }
    });
  }

  Future<void> loadSeatCount() async {
    final result = await supabase
        .from('library_logs')
        .select('id')
        .eq('status', 'checked_in');

    if (mounted) {
      setState(() {
        occupiedSeats = (result as List).length;
        loadingSeats = false;
      });
    }
  }

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

    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Check already checked in
    final existingCheckin = await supabase
        .from('library_logs')
        .select()
        .eq('uid', user.id)
        .eq('status', 'checked_in');

    if ((existingCheckin as List).isNotEmpty) {
      if (!mounted) return;
      final logData = existingCheckin.first;
      final existingSeat = logData["seat_number"] ?? 1;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Already checked in — Seat $existingSeat")),
      );
      final logId = logData["id"].toString();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LibrarySeatMapPage(existingLogId: logId),
        ),
      );
      return;
    }

    // Fetch student data
    final studentResult = await supabase
        .from('students')
        .select()
        .eq('uid', user.id)
        .maybeSingle();

    if (studentResult == null) {
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
          studentUid: user.id,
          studentData: studentResult,
        ),
      ),
    );
  }

  Future<void> handleAttendanceScan(String scanned) async {
    final parts = scanned.split(":");
    if (parts.length < 5) return;

    final facultyUid = parts[1];
    final date = parts[4];

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final studentResult = await supabase
        .from('students')
        .select()
        .eq('uid', user.id)
        .maybeSingle();

    if (studentResult == null) return;
    final studentData = studentResult;

    final existing = await supabase
        .from('attendance')
        .select('id')
        .eq('student_uid', user.id)
        .eq('faculty_uid', facultyUid)
        .eq('date', date);

    if ((existing as List).isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance already marked for today!")),
      );
      return;
    }

    await supabase.from('attendance').insert({
      'student_uid': user.id,
      'student_name': studentData["name"],
      'student_id': studentData["student_id"],
      'department': studentData["department"],
      'semester': studentData["semester"],
      'faculty_uid': facultyUid,
      'subject': "GENERAL",
      'present': true,
      'date': date,
    });

    if (!mounted) return;

    // Navigate to seat map after successful attendance marking
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LibrarySeatMapPage(studentUid: user.id, studentData: studentData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableSeats = (totalSeats - occupiedSeats).clamp(0, totalSeats);
    final isFull = availableSeats <= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F1EB),
      body: SingleChildScrollView(
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
