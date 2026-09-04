import 'package:flutter/material.dart';
import 'main.dart';
import 'security/input_sanitizer.dart';
import 'security/rate_limiter.dart';
import 'security/security_config.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController venueCtrl = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool submitting = false;

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time != null) {
      setState(() => selectedTime = time);
    }
  }

  Future<void> createEvent() async {
    final rawTitle = titleCtrl.text;
    final sanitizedTitle = InputSanitizer.sanitizeText(rawTitle, maxLength: 120);
    final sanitizedDesc = InputSanitizer.sanitizeText(descCtrl.text, maxLength: 1000);
    final sanitizedVenue = InputSanitizer.sanitizeText(venueCtrl.text, maxLength: 100);

    if (sanitizedTitle.isEmpty || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill title and select a date")),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Rate limiting for event creation
    final rateLimitKey = 'events:create:${user.id}';
    if (!SecurityRateLimiter().canAttempt(rateLimitKey, maxAttempts: 5, window: const Duration(minutes: 1))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rate limit reached. Please wait before creating more events.")),
      );
      return;
    }
    SecurityRateLimiter().recordAttempt(rateLimitKey);

    setState(() => submitting = true);

    try {
      final uid = user.id;
      final facultyData = await supabase
          .from('faculty')
          .select('faculty_name')
          .eq('uid', uid)
          .maybeSingle();
      final facultyName = facultyData != null ? (facultyData['faculty_name'] ?? 'Faculty') : 'Faculty';

      final dateStr =
          "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
      final timeStr = selectedTime != null
          ? "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}"
          : "";

      await supabase.from('events').insert({
        'title': sanitizedTitle,
        'description': sanitizedDesc,
        'venue': sanitizedVenue,
        'date': dateStr,
        'time': timeStr,
        'created_by': uid,
        'created_by_name': facultyName,
      });

      if (!mounted) return;
      setState(() => submitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event created successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create event: ${SecurityConfig.getSafeErrorMessage(e)}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D1F1E),
        title: const Text("Create Event"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildLabel("EVENT TITLE"),
            buildInputField(titleCtrl, "Enter event title"),
            const SizedBox(height: 18),

            buildLabel("DESCRIPTION"),
            buildInputField(descCtrl, "Enter description", maxLines: 3),
            const SizedBox(height: 18),

            buildLabel("VENUE"),
            buildInputField(venueCtrl, "Enter venue"),
            const SizedBox(height: 18),

            // Date picker
            buildLabel("DATE"),
            GestureDetector(
              onTap: pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF5D1F1E), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      selectedDate != null
                          ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                          : "Select date",
                      style: TextStyle(
                        fontSize: 15,
                        color: selectedDate != null ? Colors.black87 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Time picker
            buildLabel("TIME (Optional)"),
            GestureDetector(
              onTap: pickTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Color(0xFF5D1F1E), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      selectedTime != null
                          ? selectedTime!.format(context)
                          : "Select time",
                      style: TextStyle(
                        fontSize: 15,
                        color: selectedTime != null ? Colors.black87 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D1F1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                onPressed: submitting ? null : createEvent,
                child: submitting
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("Create Event", style: TextStyle(fontSize: 17)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
      ),
    );
  }

  Widget buildInputField(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none),
      ),
    );
  }
}
