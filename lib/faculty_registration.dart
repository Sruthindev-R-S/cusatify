import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'security/input_sanitizer.dart';
import 'security/rate_limiter.dart';
import 'security/security_config.dart';
import 'faculty_home_page.dart';

class FacultyRegisterPage extends StatefulWidget {
  const FacultyRegisterPage({super.key});

  @override
  State<FacultyRegisterPage> createState() => _FacultyRegisterPageState();
}

class _FacultyRegisterPageState extends State<FacultyRegisterPage> {
  final TextEditingController facultyName = TextEditingController();
  final TextEditingController facultyId = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  String? selectedDepartment;
  String? selectedSubject;
  String? selectedSemester;
  File? _profileImage;
  bool _isRegistering = false;
  bool _obscurePassword = true;

  final List<String> semesters = ["1", "2", "3", "4", "5", "6", "7", "8"];

  final List<String> facultyDepartments = [
    "COMPUTER SCIENCE ENGINEERING",
    "CIVIL ENGINEERING",
    "MECHANICAL ENGINEERING",
    "ELECTRICAL ENGINEERING",
    "ELECTRONICS AND COMMUNICATION ENGINEERING",
    "PHOTONICS",
    "MATHEMATICS",
    "PHYSICS",
  ];

  final List<String> subjects = [
    "Chemistry",
    "Mathematics",
    "EVS",
    "Digital Electronics",
    "Basic Electrical",
    "Object Oriented Programming",
  ];

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

    final fileExt = _profileImage!.path.split('.').last.toLowerCase();
    // Validate image format
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(fileExt)) {
      throw Exception('Invalid image format. Allowed formats: JPG, PNG, WEBP');
    }

    final filePath = 'faculty/$uid.$fileExt';

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

  Future<void> registerFaculty() async {
    final sanitizedName = InputSanitizer.sanitizeText(facultyName.text);
    final validatedId = InputSanitizer.validateId(facultyId.text);
    final validatedEmail = InputSanitizer.validateAndNormalizeEmail(emailCtrl.text);
    final password = passwordCtrl.text;

    if (sanitizedName.isEmpty ||
        validatedId == null ||
        validatedEmail == null ||
        selectedDepartment == null ||
        selectedSubject == null ||
        selectedSemester == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields with valid information")));
      return;
    }

    if (!InputSanitizer.isPasswordValid(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters long")),
      );
      return;
    }

    // Rate Limiting
    final rateLimitKey = 'register:faculty:$validatedEmail';
    if (!SecurityRateLimiter().canAttempt(rateLimitKey, maxAttempts: 3, lockoutDuration: const Duration(minutes: 2))) {
      final remaining = SecurityRateLimiter().getRemainingLockoutSeconds(rateLimitKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Too many registration attempts. Please wait $remaining seconds."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    SecurityRateLimiter().recordAttempt(rateLimitKey);

    setState(() => _isRegistering = true);

    try {
      final authResponse = await supabase.auth.signUp(
        email: validatedEmail,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception("Registration failed. Please check your credentials.");
      }

      final uid = authResponse.user!.id;

      // Upload photo if selected
      final photoUrl = await uploadPhoto(uid);

      await supabase.from('faculty').upsert({
        'uid': uid,
        'faculty_name': sanitizedName,
        'faculty_id': validatedId,
        'faculty_department': selectedDepartment,
        'subject': selectedSubject,
        'semester': selectedSemester,
        'email': validatedEmail,
        'photo_url': photoUrl,
      });

      // Reset rate limit on success
      SecurityRateLimiter().reset(rateLimitKey);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Faculty Registration Successful")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FacultyHomePage()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Registration: ${SecurityConfig.getSafeErrorMessage(e)}")));
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
                "Faculty Signup",
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
                    "Welcome! Join Cusatify to manage your classes and students seamlessly.",
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
          buildTextField(
            Icons.person_pin_rounded,
            "Faculty Full Name",
            facultyName,
          ),
          const SizedBox(height: 20),
          buildTextField(Icons.badge_rounded, "Faculty ID", facultyId),
          const SizedBox(height: 20),
          buildTextField(Icons.email_rounded, "Gmail ID", emailCtrl),
          const SizedBox(height: 20),
          buildPasswordField(),
          const SizedBox(height: 20),
          buildDropdown(
            icon: Icons.account_balance_rounded,
            label: "Department",
            value: selectedDepartment,
            items: facultyDepartments,
            onChanged: (v) => setState(() => selectedDepartment = v),
          ),
          const SizedBox(height: 20),
          buildDropdown(
            icon: Icons.book_rounded,
            label: "Your Subject",
            value: selectedSubject,
            items: subjects,
            onChanged: (v) => setState(() => selectedSubject = v),
          ),
          const SizedBox(height: 20),
          buildDropdown(
            icon: Icons.view_day_rounded,
            label: "Semester You Teach",
            value: selectedSemester,
            items: semesters,
            onChanged: (v) => setState(() => selectedSemester = v),
          ),
        ],
      ),
    );
  }

  Widget buildPasswordField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7EB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: TextField(
        controller: passwordCtrl,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          icon: const Icon(Icons.lock, color: Color(0xFF5D1F1E), size: 20),
          hintText: "Password (min 6 characters)",
          hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.black38,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    );
  }

  Widget registerButton() {
    return InkWell(
      onTap: _isRegistering ? null : registerFaculty,
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
                  "Complete Faculty Registration",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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
