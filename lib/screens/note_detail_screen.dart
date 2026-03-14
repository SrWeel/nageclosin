import 'package:flutter/material.dart';

class NoteDetailScreen extends StatefulWidget {
  final String? title;
  final String? content;

  NoteDetailScreen({this.title, this.content});

  @override
  _NoteDetailScreenState createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController titleController;
  late TextEditingController contentController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.title ?? "");
    contentController = TextEditingController(text: widget.content ?? "");
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.title != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Editar nota" : "Nueva nota"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Título"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: contentController,
              decoration: InputDecoration(labelText: "Contenido"),
              maxLines: 5,
              keyboardType: TextInputType.multiline,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text(isEditing ? "Actualizar" : "Guardar"),
              onPressed: () {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("El título es obligatorio")),
                  );
                  return;
                }

                Navigator.pop(context, {
                  "title": titleController.text,
                  "content": contentController.text,
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}