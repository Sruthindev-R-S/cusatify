import 'package:flutter/material.dart';
import 'main.dart';

class StudentTimetablePage extends StatefulWidget {
  const StudentTimetablePage({super.key});

  @override
  State<StudentTimetablePage> createState() => _StudentTimetablePageState();
}

class _StudentTimetablePageState extends State<StudentTimetablePage> {
  String? semester;
  String? department;
  bool loading = true;
  List<Map<String, dynamic>> facultyEntries = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final uid = supabase.auth.currentUser!.id;
    final doc = await supabase
        .from('students')
        .select()
        .eq('uid', uid)
        .single();

    semester = doc["semester"] ?? "1";
    department = doc["department"] ?? "";

    // Query faculty teaching this semester
    final result = await supabase
        .from('faculty')
        .select()
        .eq('semester', semester!);

    if (mounted) {
      setState(() {
        facultyEntries = (result as List).cast<Map<String, dynamic>>();
        loading = false;
      });
    }
  }

  // Map subject to a color
  Color subjectColor(String subject) {
    final colors = {
      "Chemistry": Colors.teal,
      "Mathematics": Colors.indigo,
      "EVS": Colors.green,
      "Digital Electronics": Colors.deepOrange,
      "Basic Electrical": Colors.amber.shade800,
      "Object Oriented Programming": Colors.blue,
    };
    return colors[subject] ?? Colors.grey;
  }

  // Map subject to an icon
  IconData subjectIcon(String subject) {
    final icons = {
      "Chemistry": Icons.science,
      "Mathematics": Icons.calculate,
      "EVS": Icons.eco,
      "Digital Electronics": Icons.memory,
      "Basic Electrical": Icons.electrical_services,
      "Object Oriented Programming": Icons.code,
    };
    return icons[subject] ?? Icons.book;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D1F1E),
        title: const Text("Timetable"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Semester header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D1F1E),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Semester $semester",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${facultyEntries.length} subjects assigned by faculty",
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (facultyEntries.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.schedule, size: 50, color: Colors.black26),
                          const SizedBox(height: 12),
                          const Text(
                            "No faculty registered for your semester yet.\nTimetable will appear once teachers enroll.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  else
                    // Show each faculty entry as a timetable card
                    ...facultyEntries.map((f) {
                      final subject = f["subject"] ?? "Unknown";
                      final teacherName = f["faculty_name"] ?? "";
                      final dept = f["faculty_department"] ?? "";
                      final color = subjectColor(subject);
                      final icon = subjectIcon(subject);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Subject icon
                            Container(
                              height: 52,
                              width: 52,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(icon, color: color, size: 28),
                            ),
                            const SizedBox(width: 14),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subject,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 15, color: Colors.black45),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          teacherName,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.business, size: 15, color: Colors.black45),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          dept,
                                          style: const TextStyle(
                                            color: Colors.black45,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
