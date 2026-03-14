import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'student_home_page.dart';

class StudentRegisterPage extends StatefulWidget {
  const StudentRegisterPage({super.key});

  @override
  State<StudentRegisterPage> createState() => _StudentRegisterPageState();
}

class _StudentRegisterPageState extends State<StudentRegisterPage> {
  final TextEditingController name = TextEditingController();
  final TextEditingController studentId = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();

  String? selectedDepartment;
  String? selectedSemester;
  File? _profileImage;
  bool _isRegistering = false;

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

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choose Photo Source",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D1F1E).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF5D1F1E)),
                ),
                title: const Text(
                  "Camera",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D1F1E).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF5D1F1E),
                  ),
                ),
                title: const Text(
                  "Gallery",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<String?> uploadPhoto(String uid) async {
    if (_profileImage == null) return null;

    final fileExt = _profileImage!.path.split('.').last;
    final filePath = 'students/$uid.$fileExt';

    await supabase.storage
        .from('profile-photos')
        .upload(
          filePath,
          _profileImage!,
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl = supabase.storage
        .from('profile-photos')
        .getPublicUrl(filePath);

    return publicUrl;
  }

  Future<void> registerStudent() async {
    if (name.text.isEmpty ||
        studentId.text.isEmpty ||
        selectedDepartment == null ||
        selectedSemester == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isRegistering = true);

    try {
      final email = emailCtrl.text.trim();
      const defaultPassword = "123456";

      final authResponse = await supabase.auth.signUp(
        email: email,
        password: defaultPassword,
      );

      final uid = authResponse.user!.id;

      // Upload photo if selected
      final photoUrl = await uploadPhoto(uid);

      await supabase.from('students').upsert({
        'uid': uid,
        'name': name.text.trim(),
        'student_id': studentId.text.trim(),
        'department': selectedDepartment,
        'semester': selectedSemester,
        'email': email,
        'photo_url': photoUrl,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Registration Successful")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentHomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Registration Failed: $e")));
    } finally {
      if (mounted) setState(() => _isRegistering = false);
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
                    colors: [
                      Color(0xFF5D1F1E),
                      Color(0xFFAB4F41),
                      Color(0xFFCB6F4A),
                    ],
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
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Profile Photo Picker
                  photoPickerWidget(),
                  const SizedBox(height: 25),
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

  Widget photoPickerWidget() {
    return GestureDetector(
      onTap: pickImage,
      child: Column(
        children: [
          Container(
            height: 110,
            width: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _profileImage == null
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF5D1F1E),
                        Color(0xFFAB4F41),
                        Color(0xFFCB6F4A),
                      ],
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5D1F1E).withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: Colors.white, width: 4),
              image: _profileImage != null
                  ? DecorationImage(
                      image: FileImage(_profileImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _profileImage == null
                ? const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 35,
                  )
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            _profileImage == null ? "Add Your Photo" : "Tap to Change Photo",
            style: TextStyle(
              color: const Color(0xFF5D1F1E).withOpacity(0.7),
              fontWeight: FontWeight.w700,
              fontSize: 13,
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
          buildTextField(Icons.person, "Full Name", name),
          const SizedBox(height: 20),
          buildTextField(Icons.badge, "Student ID", studentId),
          const SizedBox(height: 20),
          buildTextField(Icons.email, "Gmail ID", emailCtrl),
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
      onTap: _isRegistering ? null : registerStudent,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5D1F1E), Color(0xFFAB4F41), Color(0xFFCB6F4A)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFAB4F41).withOpacity(0.35),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isRegistering
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Complete Registration",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget buildTextField(
    IconData icon,
    String label,
    TextEditingController controller,
  ) {
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
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.black38),
              ),
            ],
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
