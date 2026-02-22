import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LibrarySessionPage extends StatefulWidget {
  final String logId; // the library_logs document ID for this check-in
  final int seatNumber;

  const LibrarySessionPage({super.key, required this.logId, required this.seatNumber});

  @override
  State<LibrarySessionPage> createState() => _LibrarySessionPageState();
}

class _LibrarySessionPageState extends State<LibrarySessionPage> {
  // Timer state
  int selectedMinutes = 60; // default 1 hour
  int remainingSeconds = 0;
  bool timerRunning = false;
  bool timerFinished = false;
  Timer? _timer;

  final List<int> presetMinutes = [30, 60, 90, 120];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    setState(() {
      remainingSeconds = selectedMinutes * 60;
      timerRunning = true;
      timerFinished = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds <= 0) {
        timer.cancel();
        setState(() {
          timerRunning = false;
          timerFinished = true;
        });
        return;
      }
      setState(() {
        remainingSeconds--;
      });
    });
  }

  void stopTimer() {
    _timer?.cancel();
    setState(() {
      timerRunning = false;
    });
  }

  Future<void> checkOut() async {
    _timer?.cancel();

    // Update the library_logs entry to checked_out
    await FirebaseFirestore.instance
        .collection("library_logs")
        .doc(widget.logId)
        .update({
      "status": "checked_out",
      "checkOutTime": FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Checked out of library successfully")),
    );

    Navigator.pop(context, true); // return true to signal checkout
  }

  String formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D1F1E),
        title: const Text("Library Session"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Success check-in card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "You are checked in to the library!",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.chair_alt, color: Colors.green.shade600, size: 16),
                            const SizedBox(width: 5),
                            Text(
                              "Seat ${widget.seatNumber}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Timer display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Column(
                children: [
                  const Icon(Icons.timer, color: Color(0xFF5D1F1E), size: 36),
                  const SizedBox(height: 8),
                  const Text(
                    "Exit Timer",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Set a reminder for when to leave",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Timer countdown or selector
                  if (timerRunning || timerFinished)
                    Column(
                      children: [
                        Text(
                          timerFinished ? "Time's Up!" : formatTime(remainingSeconds),
                          style: TextStyle(
                            fontSize: timerFinished ? 30 : 48,
                            fontWeight: FontWeight.bold,
                            color: timerFinished
                                ? Colors.red
                                : const Color(0xFF5D1F1E),
                            letterSpacing: 2,
                          ),
                        ),
                        if (timerFinished) ...[
                          const SizedBox(height: 8),
                          const Icon(Icons.alarm, color: Colors.red, size: 40),
                        ],
                      ],
                    )
                  else
                    // Duration presets
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: presetMinutes.map((mins) {
                        final isSelected = selectedMinutes == mins;
                        return GestureDetector(
                          onTap: () => setState(() => selectedMinutes = mins),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF5D1F1E)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              "$mins min",
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 24),

                  // Start / Stop button
                  if (!timerFinished)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: timerRunning
                              ? Colors.orange.shade700
                              : const Color(0xFF5D1F1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: timerRunning ? stopTimer : startTimer,
                        icon: Icon(timerRunning ? Icons.stop : Icons.play_arrow),
                        label: Text(
                          timerRunning ? "Stop Timer" : "Start Timer",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Check-out button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                onPressed: checkOut,
                icon: const Icon(Icons.logout, size: 22),
                label: const Text(
                  "Check Out of Library",
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
