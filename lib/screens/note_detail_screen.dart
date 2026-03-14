import 'package:flutter/material.dart';

class NoteDetailScreen extends StatelessWidget {

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("New Note"),
      ),

      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Title"),
            ),

            SizedBox(height: 10),

            TextField(
              controller: contentController,
              decoration: InputDecoration(labelText: "Content"),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              child: Text("Save"),
              onPressed: () {

                if(titleController.text.isEmpty){
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Title required"))
                  );
                  return;
                }

                Navigator.pop(context,{
                  "title": titleController.text,
                  "content": contentController.text
                });

              },
            )

          ],
        ),
      ),
    );
  }
}