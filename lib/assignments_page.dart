import 'package:flutter/material.dart';
import 'main.dart';

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({super.key});

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  List<Map<String, dynamic>> assignments = [];
  bool loading = true;
  String? semester;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final uid = supabase.auth.currentUser!.id;
    final studentDoc = await supabase
        .from('students')
        .select()
        .eq('uid', uid)
        .single();

    semester = studentDoc["semester"] ?? "1";

    final result = await supabase
        .from('assignments')
        .select()
        .eq('semester', semester!)
        .order('due_date', ascending: true);

    if (mounted) {
      setState(() {
        assignments = (result as List).cast<Map<String, dynamic>>();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D1F1E),
        title: const Text("Assignments"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : assignments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 60, color: Colors.black26),
                      const SizedBox(height: 12),
                      Text(
                        "No assignments for Semester $semester",
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final a = assignments[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5D1F1E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.assignment,
                                color: Color(0xFF5D1F1E)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a["title"] ?? "Assignment",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  a["subject"] ?? "",
                                  style: const TextStyle(
                                      color: Colors.black54, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            a["due_date"] ?? "",
                            style: const TextStyle(
                              color: Color(0xFF5D1F1E),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
