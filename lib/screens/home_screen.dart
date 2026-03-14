import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'note_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notesJson = prefs.getString('notes');
    if (notesJson != null) {
      final List<dynamic> decoded = jsonDecode(notesJson);
      setState(() {
        notes = decoded
            .map((item) => Map<String, String>.from(item as Map))
            .toList();
      });
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notes', jsonEncode(notes));
  }

  void _deleteNote(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Eliminar nota"),
        content: Text("¿Estás seguro de que deseas eliminar esta nota?"),
        actions: [
          TextButton(
            child: Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text("Eliminar", style: TextStyle(color: Colors.red)),
            onPressed: () {
              setState(() {
                notes.removeAt(index);
              });
              _saveNotes();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _editNote(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(
          title: notes[index]["title"],
          content: notes[index]["content"],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        notes[index] = {
          "title": result["title"],
          "content": result["content"],
        };
      });
      _saveNotes();
    }
  }

  void _addNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        notes.add({
          "title": result["title"],
          "content": result["content"],
        });
      });
      _saveNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Notes"),
      ),
      body: notes.isEmpty
          ? Center(
        child: Text(
          "No hay notas aún.\nPresiona + para agregar una.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      )
          : Padding(
        padding: EdgeInsets.all(8),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _editNote(index),
              onLongPress: () => _deleteNote(index),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notes[index]["title"]!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _deleteNote(index),
                            child: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          notes[index]["content"]!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _addNote,
      ),
    );
  }
}