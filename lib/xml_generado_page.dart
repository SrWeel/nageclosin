import 'package:flutter/material.dart';

class XmlGeneradoPage extends StatelessWidget {
  const XmlGeneradoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> xmls = [
      {"nombre": "F001-0001.xml", "estado": "Pendiente"},
      {"nombre": "F001-0002.xml", "estado": "Autorizado"},
      {"nombre": "F001-0003.xml", "estado": "Error"},
    ];

    return ListView.builder(
      itemCount: xmls.length,
      itemBuilder: (context, index) {
        final xml = xmls[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.file_present),
            title: Text(xml["nombre"]),
            subtitle: Text("Estado: ${xml["estado"]}"),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Descargando ${xml["nombre"]}...")),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
