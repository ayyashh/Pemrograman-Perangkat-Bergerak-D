import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final titleTextController = TextEditingController();
  final contentTextController = TextEditingController();
  final labelTextController = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();

  Color getLabelColor(String label) {
    switch (label) {
      case 'Tugas': return Colors.red.shade100;
      case 'Ujian': return Colors.blue.shade100;
      case 'Rapat': return Colors.yellow.shade100;
      default: return Colors.green.shade100;
    }
  }

  void openNoteBox({String? docId, String? existingTitle, String? existingNote, String? existingLabel}) async {
    if (docId != null) {

      titleTextController.text = existingTitle ?? ''; // Kalo gak ada isinya string kosong
      contentTextController.text = existingNote ?? '';
      labelTextController.text = existingLabel ?? '';

    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(docId == null ? "Create new Note" : "Edit Note"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: "Title"),
                controller: titleTextController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: "Content"),
                controller: contentTextController,
              ),
              TextField(
                decoration: InputDecoration(labelText: "Label (Tugas, Ujian, Rapat)"),
                controller: labelTextController,
              )

            ],
          ),
          actions: [
            MaterialButton(
              onPressed: () {
                if (docId == null) {
                  firestoreService.addNote(
                    titleTextController.text,
                    contentTextController.text,
                    labelTextController.text,
                  );
                } else {
                  firestoreService.updateNote(
                    docId,
                    titleTextController.text,
                    contentTextController.text,
                    labelTextController.text,
                  );
                }
                titleTextController.clear();
                contentTextController.clear();

                Navigator.pop(context);
              },
              child: Text(docId == null ? "Create" : "Update"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notes"),
        leading: IconButton(
          icon: const Icon(Icons.logout, size: 20),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (!context.mounted) return;
            Navigator.pushReplacementNamed(context, 'login');
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openNoteBox,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getNotes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List notesList = snapshot.data!.docs;

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: notesList.length,
              itemBuilder: (context, index) {
                DocumentSnapshot document = notesList[index];
                Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                
                String docId = document.id;
                String title = data['title'] ?? '';
                String note = data['content'] ?? '';
                String label = data['label'] ?? '';
                
                // Ambil tanggal
                Timestamp t = data['createdAt'] ?? Timestamp.now();
                DateTime d = t.toDate();
                String dateStr = "${d.day}/${d.month}/${d.year}";
                return GestureDetector(
                  onTap: () => openNoteBox(docId: docId, existingTitle: title, existingNote: note, existingLabel: label),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: getLabelColor(label), // Warna sesuai label
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4, offset: const Offset(2, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(dateStr, style: TextStyle(color: Colors.black54, fontSize: 10)),
                        const SizedBox(height: 8),
                        Expanded(child: Text(note, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 4)),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                            onPressed: () => firestoreService.deleteNote(docId),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return const Text("No data");
          }
        },
      ),
    );
  }
}