import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'library_page.dart';
import 'student_timetable_page.dart';
import 'notes_page.dart';
import 'assignments_page.dart';
import 'notices_page.dart';
import 'courses_page.dart';
import 'role_selection_page.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  Map<String, dynamic>? student;
  List<String> subjects = [];
  Map<String, double> attendancePercent = {};
  Map<String, String> attendanceFraction = {};
  bool loadingAttendance = true;
  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    loadStudentData();
  }

  Future<void> loadStudentData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("students")
        .doc(uid)
        .get();

    if (mounted) {
      setState(() {
        student = doc.data();
      });
      await loadSubjectsFromFaculty();
      await loadAttendanceData(uid);
      await loadEvents();
    }
  }

  Future<void> loadSubjectsFromFaculty() async {
    final department = student?["department"];
    final semester = student?["semester"];
    if (department == null || semester == null) return;

    final query = await FirebaseFirestore.instance
        .collection("faculty")
        .where("facultyDepartment", isEqualTo: department)
        .where("semester", isEqualTo: semester)
        .get();

    if (mounted) {
      setState(() {
        subjects = query.docs
            .map((doc) => doc.data()["subject"] as String?)
            .where((s) => s != null && s.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();
      });
    }
  }

  Future<void> loadAttendanceData(String uid) async {
    Map<String, double> percents = {};
    Map<String, String> fractions = {};

    for (final subject in subjects) {
      final query = await FirebaseFirestore.instance
          .collection("attendance")
          .where("studentUid", isEqualTo: uid)
          .where("subject", isEqualTo: subject)
          .get();

      int total = query.docs.length;
      int present = query.docs.where((d) => d.data()["present"] == true).length;

      percents[subject] = total > 0 ? present / total : 0.0;
      fractions[subject] = "$present/$total";
    }

    if (mounted) {
      setState(() {
        attendancePercent = percents;
        attendanceFraction = fractions;
        loadingAttendance = false;
      });
    }
  }

  Future<void> loadEvents() async {
    final query = await FirebaseFirestore.instance
        .collection("events")
        .orderBy("createdAt", descending: true)
        .get();

    if (mounted) {
      setState(() {
        events = query.docs
            .map((d) => {"id": d.id, ...d.data()})
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EB),
      body: student == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 120.0,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: const Color(0xFF5D1F1E),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(35),
                      bottomRight: Radius.circular(35),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      "Student Dashboard",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    centerTitle: true,
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF5D1F1E), Color(0xFFAB4F41), Color(0xFFCB6F4A)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(35),
                          bottomRight: Radius.circular(35),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: Colors.white),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
                          (_) => false,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        profileCard(),
                        const SizedBox(height: 25),
                        sectionHeader(Icons.check_circle_outline, "Attendance"),
                        const SizedBox(height: 15),
                        attendanceSection(),
                        const SizedBox(height: 25),
                        if (events.isNotEmpty) ...[
                          sectionHeader(Icons.event_note, "Upcoming Events"),
                          const SizedBox(height: 15),
                          eventsSection(),
                          const SizedBox(height: 25),
                        ],
                        sectionHeader(Icons.apps, "Explore Services"),
                        const SizedBox(height: 15),
                        featureGrid(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF5D1F1E), size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget profileCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D1F1E).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFEECB88).withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5D1F1E), Color(0xFFAB4F41), Color(0xFFCB6F4A)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5D1F1E).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 35),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student!["name"],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "ID: ${student!["studentId"]}",
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "${student!["department"]} • Sem ${student!["semester"]}",
                  style: const TextStyle(
                    color: Color(0xFF5D1F1E),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget attendanceSection() {

    if (subjects.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Text("No subjects selected"),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: loadingAttendance
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: subjects.map((subject) {
                  final percent = attendancePercent[subject] ?? 0.0;
                  final fraction = attendanceFraction[subject] ?? "0/0";
                  final color = percent >= 0.75
                      ? Colors.teal
                      : percent >= 0.5
                          ? Colors.orangeAccent
                          : Colors.redAccent;

                  return Container(
                    width: 110,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        CircularPercentIndicator(
                          radius: 40.0,
                          lineWidth: 8.0,
                          percent: percent,
                          center: Text(
                            "${(percent * 100).toInt()}%",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: color,
                            ),
                          ),
                          progressColor: color,
                          backgroundColor: color.withOpacity(0.1),
                          circularStrokeCap: CircularStrokeCap.round,
                          animation: true,
                          animationDuration: 1000,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subject,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            fraction,
                            style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget eventsSection() {
    return Column(
      children: events.take(3).map((e) => Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.deepOrange.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepOrange.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.event, color: Colors.deepOrange, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e["title"] ?? "",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: Colors.black45),
                          const SizedBox(width: 5),
                          Text(
                            "${e["date"]} • ${e["time"] ?? "TBA"}",
                            style: const TextStyle(color: Colors.black45, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black12),
              ],
            ),
          )).toList(),
    );
  }

  Widget featureGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      childAspectRatio: 1.1,
      children: [
        featureTile(Icons.schedule_rounded, "Timetable", const Color(0xFF5D1F1E), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentTimetablePage()));
        }),
        featureTile(Icons.note_alt_rounded, "My Notes", Colors.amber.shade900, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesPage()));
        }),
        featureTile(Icons.assignment_rounded, "Assignments", Colors.blue.shade800, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentsPage()));
        }),
        featureTile(Icons.campaign_rounded, "Notices", Colors.teal.shade700, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticesPage()));
        }),
        featureTile(Icons.book_rounded, "Resources", Colors.indigo.shade800, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CoursesPage()));
        }),
        featureTile(Icons.local_library_rounded, "Library", Colors.brown.shade700, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryPage()));
        }),
      ],
    );
  }

  Widget featureTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
