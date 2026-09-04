import 'package:flutter/material.dart';
import 'main.dart';
import 'security/input_sanitizer.dart';
import 'security/rate_limiter.dart';
import 'security/security_config.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, dynamic>> notes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final result = await supabase
          .from('notes')
          .select()
          .eq('user_uid', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          notes = (result as List).cast<Map<String, dynamic>>();
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(SecurityConfig.getSafeErrorMessage(e))),
        );
      }
    }
  }

  Future<void> addNote(String title, String content) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final sanitizedTitle = InputSanitizer.sanitizeText(title, maxLength: 100);
    final sanitizedContent = InputSanitizer.sanitizeText(content, maxLength: 2000);

    if (sanitizedTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Note title cannot be empty")),
      );
      return;
    }

    // Rate Limiting
    final rateLimitKey = 'notes:create:${user.id}';
    if (!SecurityRateLimiter().canAttempt(rateLimitKey, maxAttempts: 15, window: const Duration(minutes: 1))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rate limit reached. Please wait before creating more notes.")),
      );
      return;
    }
    SecurityRateLimiter().recordAttempt(rateLimitKey);

    try {
      await supabase.from('notes').insert({
        'user_uid': user.id,
        'title': sanitizedTitle,
        'content': sanitizedContent,
      });
      loadNotes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save note: ${SecurityConfig.getSafeErrorMessage(e)}")),
        );
      }
    }
  }

  Future<void> deleteNote(dynamic noteId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Scoped deletion: only delete if the note belongs to the authenticated user
      await supabase
          .from('notes')
          .delete()
          .eq('id', noteId)
          .eq('user_uid', user.id);
      loadNotes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete note: ${SecurityConfig.getSafeErrorMessage(e)}")),
        );
      }
    }
  }

  void showAddNoteDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("New Note", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: "Title",
                counterText: "",
                filled: true,
                fillColor: const Color(0xFFFAF7EB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: contentCtrl,
              maxLines: 4,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: "Write your note...",
                counterText: "",
                filled: true,
                fillColor: const Color(0xFFFAF7EB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D1F1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                addNote(titleCtrl.text, contentCtrl.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D1F1E),
        title: const Text("My Notes"),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5D1F1E),
        onPressed: showAddNoteDialog,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_alt_outlined, size: 60, color: Colors.black26),
                      const SizedBox(height: 12),
                      const Text("No notes yet", style: TextStyle(color: Colors.black54, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final n = notes[index];
                    return Dismissible(
                      key: Key(n["id"].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => deleteNote(n["id"]),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n["title"] ?? "",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            if ((n["content"] ?? "").isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                n["content"],
                                style: const TextStyle(color: Colors.black54, fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
