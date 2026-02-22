import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendancePage extends StatefulWidget {
  final String semester;
  final String facultySubject;

  const AttendancePage({
    super.key,
    required this.semester,
    required this.facultySubject,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<Map<String, dynamic>> students = [];
  Set<String> presentUids = {};
  bool loading = true;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    final query = await FirebaseFirestore.instance
        .collection("students")
        .where("semester", isEqualTo: widget.semester)
        .get();

    if (mounted) {
      setState(() {
        students = query.docs
            .map((doc) => {"uid": doc.id, ...doc.data()})
            .toList();
        loading = false;
      });
    }
  }

  Future<void> submitAttendance() async {
    setState(() => submitting = true);

    final facultyUid = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final batch = FirebaseFirestore.instance.batch();

    for (final student in students) {
      final docRef = FirebaseFirestore.instance.collection("attendance").doc();
      batch.set(docRef, {
        "subject": widget.facultySubject,
        "semester": widget.semester,
        "date": dateStr,
        "studentUid": student["uid"],
        "studentName": student["name"],
        "studentId": student["studentId"],
        "present": presentUids.contains(student["uid"]),
        "markedBy": facultyUid,
        "timestamp": FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    if (!mounted) return;

    setState(() => submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Attendance submitted — ${presentUids.length}/${students.length} present",
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D1F1E),
        elevation: 0,
        title: Text("Manual Attendance", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                headerCard(),
                selectionTools(),
                Expanded(child: studentList()),
                submitButtonContainer(),
              ],
            ),
    );
  }

  Widget headerCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF5D1F1E), Color(0xFFAB4F41)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: const Color(0xFF5D1F1E).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.facultySubject.toUpperCase(),
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          const SizedBox(height: 5),
          Text(
            "Semester ${widget.semester}",
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Text(
              "${students.length} Students Enrolled",
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget selectionTools() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: [
          actionChip("Select All", Icons.check_circle_rounded, () {
            setState(() => presentUids = students.map((s) => s["uid"] as String).toSet());
          }, const Color(0xFF5D1F1E)),
          const SizedBox(width: 12),
          actionChip("Clear All", Icons.remove_circle_outline_rounded, () {
            setState(() => presentUids.clear());
          }, Colors.black45),
        ],
      ),
    );
  }

  Widget actionChip(String label, IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget studentList() {
    if (students.isEmpty) {
      return const Center(child: Text("No students found", style: TextStyle(color: Colors.black26)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        final uid = s["uid"] as String;
        final isPresent = presentUids.contains(uid);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: isPresent ? const Color(0xFF5D1F1E).withOpacity(0.1) : Colors.transparent),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: isPresent ? const Color(0xFF5D1F1E).withOpacity(0.1) : const Color(0xFFFAF7EB),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_rounded, color: isPresent ? const Color(0xFF5D1F1E) : Colors.black26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s["name"] ?? "", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text("ID: ${s["studentId"]}", style: const TextStyle(color: Colors.black38, fontSize: 12)),
                  ],
                ),
              ),
              Checkbox(
                value: isPresent,
                activeColor: const Color(0xFF5D1F1E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                onChanged: (val) {
                  setState(() {
                    if (val == true) presentUids.add(uid);
                    else presentUids.remove(uid);
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget submitButtonContainer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: InkWell(
        onTap: submitting ? null : submitAttendance,
        child: Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF5D1F1E), Color(0xFFAB4F41)]),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: const Color(0xFF5D1F1E).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
            ],
          ),
          child: Center(
            child: submitting
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    "Submit Attendance (${presentUids.length}/${students.length})",
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
