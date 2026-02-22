import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'library_session_page.dart';

/// Displays 30 library seats in real-time.
/// When [studentUid] and [studentData] are provided, runs in SELECTION mode:
/// the student picks a free seat, confirms, and a log entry is created.
/// Otherwise it's view-only.
class LibrarySeatMapPage extends StatefulWidget {
  final String? studentUid;
  final Map<String, dynamic>? studentData;
  /// If already checked-in, pass the existing logId to go straight to session.
  final String? existingLogId;

  const LibrarySeatMapPage({
    super.key,
    this.studentUid,
    this.studentData,
    this.existingLogId,
  });

  @override
  State<LibrarySeatMapPage> createState() => _LibrarySeatMapPageState();
}

class _LibrarySeatMapPageState extends State<LibrarySeatMapPage> {
  static const int totalSeats = 30;
  int? _selectedSeat; // tapped seat index (0-based)

  bool get isSelectionMode => widget.studentUid != null && widget.studentData != null;

  // ── Confirm & Check In ──────────────────────────────────────────────────────
  Future<void> _confirmSeat(int seatIndex, Set<int> occupiedIndexes) async {
    if (occupiedIndexes.contains(seatIndex)) return;

    final seatNumber = seatIndex + 1;
    final uid = widget.studentUid!;
    final studentData = widget.studentData!;
    final now = DateTime.now();

    // Create the library_log entry
    final logRef = await FirebaseFirestore.instance.collection("library_logs").add({
      "uid": uid,
      "name": studentData["name"],
      "studentId": studentData["studentId"],
      "department": studentData["department"],
      "semester": studentData["semester"],
      "seatNumber": seatNumber,
      "timestamp": FieldValue.serverTimestamp(),
      "date": "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
      "time": "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
      "status": "checked_in",
    });

    if (!mounted) return;

    // Navigate to session/timer page
    final checkedOut = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibrarySessionPage(
          logId: logRef.id,
          seatNumber: seatNumber,
        ),
      ),
    );

    if (!mounted) return;
    Navigator.pop(context, checkedOut == true);
  }

  // ── Seat-tap handler ────────────────────────────────────────────────────────
  void _onSeatTap(int index, Set<int> occupiedIndexes) {
    if (!isSelectionMode) return;
    if (occupiedIndexes.contains(index)) return;

    setState(() => _selectedSeat = index);

    final seatNumber = index + 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSeatSheet(
        seatNumber: seatNumber,
        onConfirm: () {
          Navigator.pop(context); // close sheet
          _confirmSeat(index, occupiedIndexes);
        },
        onCancel: () {
          Navigator.pop(context);
          setState(() => _selectedSeat = null);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D1F1E),
        elevation: 0,
        title: Text(
          isSelectionMode ? "Pick Your Seat" : "Library Seats",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("library_logs")
            .where("status", isEqualTo: "checked_in")
            .snapshots(),
        builder: (context, snapshot) {
          // Get occupied seat indexes (0-based) from Firestore
          final Set<int> occupiedIndexes = {};
          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final sn = data["seatNumber"];
              if (sn != null) occupiedIndexes.add((sn as int) - 1);
            }
          }

          final occupied = occupiedIndexes.length;
          final available = (totalSeats - occupied).clamp(0, totalSeats);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ── Stats banner ───────────────────────────────────────
                _StatsBanner(total: totalSeats, occupied: occupied, available: available),

                const SizedBox(height: 20),

                // ── Instruction chip ──────────────────────────────────
                if (isSelectionMode)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D1F1E).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Tap a green seat to select it",
                      style: TextStyle(
                        color: Color(0xFF5D1F1E),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // ── Legend ─────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendDot(color: Colors.green.shade400, label: "Available"),
                    const SizedBox(width: 20),
                    _LegendDot(color: Colors.red.shade400, label: "Occupied"),
                    if (isSelectionMode) ...[
                      const SizedBox(width: 20),
                      _LegendDot(color: Colors.amber.shade600, label: "Selected"),
                    ],
                  ],
                ),

                const SizedBox(height: 22),

                // ── Seat grid ──────────────────────────────────────────
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: totalSeats,
                  itemBuilder: (context, index) {
                    final isOccupied = occupiedIndexes.contains(index);
                    final isSelected = _selectedSeat == index;

                    Color color;
                    if (isSelected) {
                      color = Colors.amber.shade600;
                    } else if (isOccupied) {
                      color = Colors.red.shade400;
                    } else {
                      color = Colors.green.shade400;
                    }

                    return GestureDetector(
                      onTap: () => _onSeatTap(index, occupiedIndexes),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: color.withValues(alpha: isSelected ? 1.0 : 0.45),
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.18),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isOccupied ? Icons.event_seat : Icons.chair_alt,
                              color: color,
                              size: 26,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${index + 1}",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Confirm-seat bottom sheet ─────────────────────────────────────────────────
class _ConfirmSeatSheet extends StatelessWidget {
  final int seatNumber;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ConfirmSeatSheet({
    required this.seatNumber,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chair_alt, color: Colors.green.shade600, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            "Seat $seatNumber",
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            "Confirm this seat? A timer will start after check-in.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black26),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.black54, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D1F1E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Check In",
                      style: TextStyle(fontSize: 15, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _StatsBanner extends StatelessWidget {
  final int total, occupied, available;
  const _StatsBanner(
      {required this.total, required this.occupied, required this.available});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF5D1F1E), Color(0xFFAB4F41)]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D1F1E).withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _pill(Icons.event_seat, "$total", "Total"),
          _pill(Icons.person, "$occupied", "Occupied"),
          _pill(Icons.chair_alt, "$available", "Free"),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String value, String label) => Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
