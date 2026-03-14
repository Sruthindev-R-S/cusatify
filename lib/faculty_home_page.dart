import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'main.dart';
import 'attendance_page.dart';
import 'create_event_page.dart';
import 'role_selection_page.dart';
import 'enrolled_students_page.dart';

class FacultyHomePage extends StatefulWidget {
  const FacultyHomePage({super.key});

  @override
  State<FacultyHomePage> createState() => _FacultyHomePageState();
}

class _FacultyHomePageState extends State<FacultyHomePage> {
  Map<String, dynamic>? faculty;
  String selectedSemester = "1";
  int studentCount = 0;
  bool loadingCount = false;
  List<Map<String, dynamic>> timetableEntries = [];
  bool loadingTimetable = false;
  List<Map<String, dynamic>> libraryLogs = [];
  bool loadingLibraryLogs = false;

  final List<String> semesters = ["1", "2", "3", "4", "5", "6", "7", "8"];

  @override
  void initState() {
    super.initState();
    loadFacultyData();
  }

  Future<void> loadFacultyData() async {
    final uid = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('faculty')
        .select()
        .eq('uid', uid)
        .single();

    if (mounted) {
      setState(() {
        faculty = data;
        selectedSemester = faculty?["semester"] ?? "1";
      });
      loadStudentCount();
      loadTimetable();
      loadLibraryLogs();
    }
  }

  Future<void> loadStudentCount() async {
    setState(() => loadingCount = true);

    final result = await supabase
        .from('students')
        .select('uid')
        .eq('semester', selectedSemester);

    if (mounted) {
      setState(() {
        studentCount = (result as List).length;
        loadingCount = false;
      });
    }
  }

  Future<void> loadTimetable() async {
    setState(() => loadingTimetable = true);

    final result = await supabase
        .from('faculty')
        .select()
        .eq('semester', selectedSemester);

    if (mounted) {
      setState(() {
        timetableEntries = (result as List).cast<Map<String, dynamic>>();
        loadingTimetable = false;
      });
    }
  }

  Future<void> loadLibraryLogs() async {
    setState(() => loadingLibraryLogs = true);

    final result = await supabase
        .from('library_logs')
        .select()
        .order('timestamp', ascending: false)
        .limit(20);

    if (mounted) {
      setState(() {
        libraryLogs = (result as List).cast<Map<String, dynamic>>();
        loadingLibraryLogs = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EB),
      body: faculty == null
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
                      "Faculty Dashboard",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    centerTitle: true,
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF5D1F1E),
                            Color(0xFFAB4F41),
                            Color(0xFFCB6F4A),
                          ],
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
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        await supabase.auth.signOut();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RoleSelectionPage(),
                          ),
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
                      children: [
                        profileCard(),
                        const SizedBox(height: 25),
                        semesterSelector(),
                        const SizedBox(height: 20),
                        statsSection(),
                        const SizedBox(height: 25),
                        timetableCard(),
                        const SizedBox(height: 25),
                        inlineQRCard(),
                        const SizedBox(height: 20),
                        markAttendanceButton(),
                        const SizedBox(height: 15),
                        viewStudentsButton(),
                        const SizedBox(height: 25),
                        libraryLogSection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEventPage()),
          );
        },
        backgroundColor: const Color(0xFFCB6F4A),
        icon: const Icon(Icons.event_available),
        label: const Text(
          "Create Event",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget inlineQRCard() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final facultyUid = supabase.auth.currentUser!.id;
    final qrData = "ATTENDANCE:$facultyUid:GENERAL:ALL:$dateStr";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFEECB88).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCB6F4A).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_rounded, color: Color(0xFF5D1F1E)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Attendance QR",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 8),
                    SizedBox(width: 6),
                    Text(
                      "LIVE",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            "General Attendance • All Semesters • $dateStr",
            style: const TextStyle(
              color: Colors.black38,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7EB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200.0,
              gapless: true,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.circle,
                color: Color(0xFF5D1F1E),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: Color(0xFF5D1F1E),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Students scan this to mark attendance",
            style: TextStyle(
              color: Colors.black26,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget profileCard() {
    final photoUrl = faculty?["photo_url"];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCB6F4A).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFEECB88).withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              gradient: photoUrl == null
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF5D1F1E),
                        Color(0xFFAB4F41),
                        Color(0xFFCB6F4A),
                      ],
                    )
                  : null,
              shape: BoxShape.circle,
              image: photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photoUrl == null
                ? const Icon(Icons.person, color: Colors.white, size: 35)
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faculty!["faculty_name"] ?? "",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Dept: ${faculty!["faculty_department"] ?? ""}",
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "ID: ${faculty!["faculty_id"]}",
                  style: const TextStyle(color: Colors.black45, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget semesterSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, color: Color(0xFF5D1F1E), size: 20),
          const SizedBox(width: 15),
          const Text(
            "Select Semester:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedSemester,
                items: semesters
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text("Semester $s"),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => selectedSemester = val);
                    loadStudentCount();
                    loadTimetable();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget statsSection() {
    return Row(
      children: [
        Expanded(
          child: statCard(
            "Total Students",
            studentCount.toString(),
            Icons.people_alt_rounded,
            const Color(0xFF5D1F1E),
            loadingCount,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: statCard(
            "My Subject",
            faculty!["subject"] ?? "N/A",
            Icons.book_rounded,
            Colors.teal.shade700,
            false,
          ),
        ),
      ],
    );
  }

  Widget statCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool loading,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 15),
          loading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black38,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget timetableCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_view_day_rounded, color: Color(0xFF5D1F1E)),
              SizedBox(width: 12),
              Text(
                "Faculty & Subjects",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 20),
          loadingTimetable
              ? const Center(child: CircularProgressIndicator())
              : timetableEntries.isEmpty
              ? const Text(
                  "No records found",
                  style: TextStyle(color: Colors.black26),
                )
              : Column(
                  children: timetableEntries
                      .map(
                        (f) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF7EB),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFF5D1F1E).withOpacity(0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF5D1F1E,
                                  ).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF5D1F1E),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      f["subject"] ?? "",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      "${f["faculty_name"]} • ${f["faculty_department"]}",
                                      style: const TextStyle(
                                        color: Colors.black45,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget markAttendanceButton() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendancePage(
              semester: selectedSemester,
              facultySubject: faculty!["subject"] ?? "",
            ),
          ),
        );
      },
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5D1F1E), Color(0xFFAB4F41)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5D1F1E).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fact_check_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text(
              "Mark Attendance",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget viewStudentsButton() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EnrolledStudentsPage()),
        );
      },
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF5D1F1E).withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5D1F1E).withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt_rounded, color: Color(0xFF5D1F1E)),
            SizedBox(width: 12),
            Text(
              "View Enrolled Students",
              style: TextStyle(
                color: Color(0xFF5D1F1E),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget libraryLogSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFEECB88).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCB6F4A).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_library_rounded, color: Color(0xFF5D1F1E)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Library Log",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              InkWell(
                onTap: loadLibraryLogs,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D1F1E).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: Color(0xFF5D1F1E), size: 14),
                      SizedBox(width: 4),
                      Text(
                        "Refresh",
                        style: TextStyle(
                          color: Color(0xFF5D1F1E),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          loadingLibraryLogs
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              : libraryLogs.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "No library check-ins yet",
                      style: TextStyle(color: Colors.black26, fontSize: 14),
                    ),
                  ),
                )
              : Column(
                  children: libraryLogs.map((log) {
                    final isCheckedIn = log["status"] == "checked_in";
                    final name = log["name"] ?? "Unknown";
                    final studentId = log["student_id"] ?? "";
                    final date = log["date"] ?? "";
                    final time = log["time"] ?? "";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7EB),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFEECB88).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: isCheckedIn
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCheckedIn
                                  ? Icons.login_rounded
                                  : Icons.logout_rounded,
                              color: isCheckedIn ? Colors.green : Colors.grey,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "ID: $studentId",
                                  style: const TextStyle(
                                    color: Colors.black38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isCheckedIn
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isCheckedIn ? "IN" : "OUT",
                                  style: TextStyle(
                                    color: isCheckedIn
                                        ? Colors.green
                                        : Colors.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                date,
                                style: const TextStyle(
                                  color: Colors.black38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                time,
                                style: const TextStyle(
                                  color: Colors.black26,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}
