import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/note.dart';

class NoteViewModel extends ChangeNotifier {

  List<Note> notes = [];

  Future loadNotes() async {

    notes = await DatabaseHelper.instance.getNotes();

    notifyListeners();
  }

  Future addNote(Note note) async {

    await DatabaseHelper.instance.insert(note);

    await loadNotes();
  }

  Future updateNote(Note note) async {

    await DatabaseHelper.instance.update(note);

    await loadNotes();
  }

  Future deleteNote(int id) async {

    await DatabaseHelper.instance.delete(id);

    await loadNotes();
  }
}