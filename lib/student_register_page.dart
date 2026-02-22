import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student_home_page.dart';

class StudentRegisterPage extends StatefulWidget {
  const StudentRegisterPage({super.key});

  @override
  State<StudentRegisterPage> createState() => _StudentRegisterPageState();
}

class _StudentRegisterPageState extends State<StudentRegisterPage> {
  final TextEditingController name = TextEditingController();
  final TextEditingController studentId = TextEditingController();

  String? selectedDepartment;
  String? selectedSemester;

  final List<String> departments = [
    "COMPUTER SCIENCE ENGINEERING",
    "CIVIL ENGINEERING",
    "MECHANICAL ENGINEERING",
    "FIRE AND SAFETY",
    "ELECTRICAL ENGINEERING",
    "ELECTRONICS AND COMMUNICATION ENGINEERING",
    "PHOTONICS",
    "MATHEMATICS",
    "PHYSICS",
  ];

  final List<String> semesters = ["1", "2", "3", "4", "5", "6", "7", "8"];

  Future<void> registerStudent() async {
    if (name.text.isEmpty ||
        studentId.text.isEmpty ||
        selectedDepartment == null ||
        selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      final email = "${studentId.text.trim()}@student.app";
      const defaultPassword = "123456";

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: defaultPassword,
      );

      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection("students").doc(uid).set({
        "name": name.text.trim(),
        "studentId": studentId.text.trim(),
        "department": selectedDepartment,
        "semester": selectedSemester,
        "email": email,
        "uid": uid,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Successful")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentHomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration Failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EB),
      body: CustomScrollView(
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
                "Student Signup",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5D1F1E), Color(0xFFAB4F41), Color(0xFFCB6F4A)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                   const Text(
                    "Welcome to Cusatify! Create your account to get started.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black45, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 30),
                  inputSection(),
                  const SizedBox(height: 40),
                  registerButton(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget inputSection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFEECB88).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFFCB6F4A).withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          buildTextField(Icons.person, "Full Name", name),
          const SizedBox(height: 20),
          buildTextField(Icons.badge, "Student ID", studentId),
          const SizedBox(height: 20),
          buildDropdown(
            icon: Icons.business,
            label: "Department",
            value: selectedDepartment,
            items: departments,
            onChanged: (v) => setState(() => selectedDepartment = v),
          ),
          const SizedBox(height: 20),
          buildDropdown(
            icon: Icons.school,
            label: "Semester",
            value: selectedSemester,
            items: semesters,
            onChanged: (v) => setState(() => selectedSemester = v),
          ),
        ],
      ),
    );
  }

  Widget registerButton() {
    return InkWell(
      onTap: registerStudent,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF5D1F1E), Color(0xFFAB4F41), Color(0xFFCB6F4A)]),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: const Color(0xFFAB4F41).withOpacity(0.35), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: const Center(
          child: Text(
            "Complete Registration",
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(IconData icon, String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7EB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          icon: Icon(icon, color: const Color(0xFF5D1F1E), size: 20),
          hintText: label,
          hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget buildDropdown({
    required IconData icon,
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7EB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, color: const Color(0xFF5D1F1E), size: 20),
              const SizedBox(width: 15),
              Text(label, style: const TextStyle(fontSize: 14, color: Colors.black38)),
            ],
          ),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
