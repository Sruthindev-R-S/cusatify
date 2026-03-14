import 'package:flutter/material.dart';
import 'main.dart';

class EnrolledStudentsPage extends StatefulWidget {
  const EnrolledStudentsPage({super.key});

  @override
  State<EnrolledStudentsPage> createState() => _EnrolledStudentsPageState();
}

class _EnrolledStudentsPageState extends State<EnrolledStudentsPage> {
  String? selectedSemester;
  String? selectedDepartment;
  List<Map<String, dynamic>> students = [];
  bool loading = false;
  bool hasSearched = false;

  final List<String> semesters = ["1", "2", "3", "4", "5", "6", "7", "8"];

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

  Future<void> fetchStudents() async {
    if (selectedSemester == null || selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both semester and department")),
      );
      return;
    }

    setState(() {
      loading = true;
      hasSearched = true;
    });

    final result = await supabase
        .from('students')
        .select()
        .eq('semester', selectedSemester!)
        .eq('department', selectedDepartment!)
        .order('name', ascending: true);

    if (mounted) {
      setState(() {
        students = (result as List).cast<Map<String, dynamic>>();
        loading = false;
      });
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
                "Enrolled Students",
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
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Filter card
                  _filterCard(),
                  const SizedBox(height: 20),

                  // Results
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    )
                  else if (hasSearched && students.isEmpty)
                    _emptyState()
                  else if (hasSearched)
                    _studentsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFEECB88).withOpacity(0.3), width: 1.5),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D1F1E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.filter_list_rounded, color: Color(0xFF5D1F1E), size: 22),
              ),
              const SizedBox(width: 14),
              const Text(
                "Filter Students",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Semester dropdown
          _buildDropdown(
            icon: Icons.school_rounded,
            label: "Select Semester",
            value: selectedSemester,
            items: semesters.map((s) => DropdownMenuItem(value: s, child: Text("Semester $s"))).toList(),
            onChanged: (val) => setState(() => selectedSemester = val),
          ),
          const SizedBox(height: 16),

          // Department dropdown
          _buildDropdown(
            icon: Icons.account_balance_rounded,
            label: "Select Department",
            value: selectedDepartment,
            items: departments
                .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(
                        d,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (val) => setState(() => selectedDepartment = val),
          ),
          const SizedBox(height: 22),

          // Search button
          InkWell(
            onTap: fetchStudents,
            child: Container(
              height: 55,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5D1F1E), Color(0xFFAB4F41), Color(0xFFCB6F4A)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5D1F1E).withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    "Search Students",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required IconData icon,
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
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
              const SizedBox(width: 14),
              Text(label, style: const TextStyle(fontSize: 14, color: Colors.black38)),
            ],
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline_rounded, size: 60, color: Colors.black.withOpacity(0.15)),
          const SizedBox(height: 14),
          const Text(
            "No students found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            "No students enrolled in Semester ${selectedSemester ?? ''}\n${selectedDepartment ?? ''}",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _studentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5D1F1E), Color(0xFFAB4F41)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.people_alt_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Text(
                "${students.length} Student${students.length != 1 ? 's' : ''} Found",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Sem $selectedSemester",
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Student cards
        ...students.asMap().entries.map((entry) {
          final index = entry.key;
          final s = entry.value;
          final photoUrl = s["photo_url"];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Serial number badge
                Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D1F1E).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: Color(0xFF5D1F1E),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Profile photo
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: photoUrl == null
                        ? const LinearGradient(
                            colors: [Color(0xFF5D1F1E), Color(0xFFAB4F41)],
                          )
                        : null,
                    image: photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: photoUrl == null
                      ? const Icon(Icons.person_rounded, color: Colors.white, size: 26)
                      : null,
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s["name"] ?? "",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5D1F1E).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "ID: ${s["student_id"] ?? ""}",
                              style: const TextStyle(
                                color: Color(0xFF5D1F1E),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Sem ${s["semester"] ?? ""}",
                              style: TextStyle(
                                color: Colors.teal.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.business_rounded, size: 13, color: Colors.black38),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              s["department"] ?? "",
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
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
    );
  }
}
