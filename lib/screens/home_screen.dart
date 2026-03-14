import 'package:flutter/material.dart';
import 'note_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  List<Map<String,String>> notes = [];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("My Notes"),
      ),

      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context,index){

          return ListTile(
            title: Text(notes[index]["title"]!),
            subtitle: Text(notes[index]["content"]!),
          );

        },
      ),

      floatingActionButton: FloatingActionButton(

        child: Icon(Icons.add),

        onPressed: () async {

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(),
            ),
          );

          if(result != null){

            setState(() {

              notes.add({
                "title": result["title"],
                "content": result["content"]
              });

            });

          }

        },

      ),
    );
  }
}