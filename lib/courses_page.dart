import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  List<String> subjects = [];
  Map<String, String> facultyBySubject = {};
  bool loading = true;
  String? semester;
  String? department;

  // Subject descriptions
  final Map<String, Map<String, dynamic>> subjectInfo = {
    "Chemistry": {
      "icon": Icons.science,
      "color": Colors.teal,
      "desc": "General and organic chemistry fundamentals",
    },
    "Mathematics": {
      "icon": Icons.calculate,
      "color": Colors.indigo,
      "desc": "Calculus, linear algebra, and differential equations",
    },
    "EVS": {
      "icon": Icons.eco,
      "color": Colors.green,
      "desc": "Environmental studies and sustainability",
    },
    "Digital Electronics": {
      "icon": Icons.memory,
      "color": Colors.deepOrange,
      "desc": "Logic gates, circuits, and digital systems",
    },
    "Basic Electrical": {
      "icon": Icons.electrical_services,
      "color": Colors.amber.shade800,
      "desc": "Electrical circuits, transformers, and machines",
    },
    "Object Oriented Programming": {
      "icon": Icons.code,
      "color": Colors.blue,
      "desc": "OOP concepts, classes, inheritance, and polymorphism",
    },
  };

  @override
  void initState() {
    super.initState();
    loadCourses();
  }

  Future<void> loadCourses() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection("students")
        .doc(uid)
        .get();

    semester = doc.data()?["semester"];
    department = doc.data()?["department"];

    if (semester != null && department != null) {
      final facultyQuery = await FirebaseFirestore.instance
          .collection("faculty")
          .where("facultyDepartment", isEqualTo: department)
          .where("semester", isEqualTo: semester)
          .get();

      final Map<String, String> facultyMap = {};
      final Set<String> subjectSet = {};

      for (final fDoc in facultyQuery.docs) {
        final subject = fDoc.data()["subject"] as String?;
        final name = fDoc.data()["facultyName"] as String?;
        if (subject != null && subject.isNotEmpty) {
          subjectSet.add(subject);
          facultyMap[subject] = name ?? "Unknown";
        }
      }

      if (mounted) {
        setState(() {
          subjects = subjectSet.toList();
          facultyBySubject = facultyMap;
          loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D1F1E),
        title: const Text("My Courses"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
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
                          "${subjects.length} courses enrolled",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Course cards
                  ...subjects.map((subject) {
                    final info = subjectInfo[subject] ??
                        {
                          "icon": Icons.book,
                          "color": Colors.grey,
                          "desc": "",
                        };

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: (info["color"] as Color).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              info["icon"] as IconData,
                              color: info["color"] as Color,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subject,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if ((info["desc"] as String).isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    info["desc"] as String,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                                if (facultyBySubject.containsKey(subject)) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 14, color: Color(0xFF5D1F1E)),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Faculty: ${facultyBySubject[subject]}",
                                        style: const TextStyle(
                                          color: Color(0xFF5D1F1E),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
