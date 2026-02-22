import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();
  List<Map<String, dynamic>> notes = [];
  bool loading = true;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    final query = await FirebaseFirestore.instance
        .collection("students")
        .doc(uid)
        .collection("notes")
        .orderBy("createdAt", descending: true)
        .get();

    if (mounted) {
      setState(() {
        notes = query.docs
            .map((d) => {"id": d.id, ...d.data()})
            .toList();
        loading = false;
      });
    }
  }

  Future<void> addNote() async {
    if (_titleCtrl.text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection("students")
        .doc(uid)
        .collection("notes")
        .add({
      "title": _titleCtrl.text,
      "content": _contentCtrl.text,
      "createdAt": FieldValue.serverTimestamp(),
    });

    _titleCtrl.clear();
    _contentCtrl.clear();
    Navigator.pop(context);
    loadNotes();
  }

  Future<void> deleteNote(String noteId) async {
    await FirebaseFirestore.instance
        .collection("students")
        .doc(uid)
        .collection("notes")
        .doc(noteId)
        .delete();

    loadNotes();
  }

  void showAddNoteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "New Note",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Content",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D1F1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: addNote,
                child: const Text("Save Note", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D1F1E),
        title: const Text("Notes"),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5D1F1E),
        onPressed: showAddNoteDialog,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
              ? const Center(
                  child: Text(
                    "No notes yet.\nTap + to add one!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  note["title"] ?? "",
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red, size: 22),
                                onPressed: () => deleteNote(note["id"]),
                              ),
                            ],
                          ),
                          if ((note["content"] ?? "").isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              note["content"],
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
