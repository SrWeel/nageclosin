import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

class DetalleFacturaPage extends StatefulWidget {
  final Map<String, dynamic> factura;

  const DetalleFacturaPage({Key? key, required this.factura}) : super(key: key);

  @override
  State<DetalleFacturaPage> createState() => _DetalleFacturaPageState();
}

class _DetalleFacturaPageState extends State<DetalleFacturaPage> {
  String? xmlPath;

  Future<void> _generarXML() async {
    final factura = widget.factura;

    try {
      const apiUrl = 'http://192.168.1.19:5110/api/SriFactura/generar-xml';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(factura),
      );

      if (response.statusCode == 200) {
        final xmlContent = response.body;

        // Guardar XML devuelto por la API
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/${factura["numero"]}.xml');
        await file.writeAsString(xmlContent);

        setState(() {
          factura["xml"] = true;
          xmlPath = file.path;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('XML generado desde API en: ${file.path}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error API: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }
  Future<void> _preguntarYCompartir() async {
    if (!widget.factura["xml"]) {
      await _generarXML(); // Genera el XML si no existe
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compartir factura'),
        content: const Text('Selecciona el formato:'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Compartir XML
              await _compartirXML();
            },
            child: const Text('XML'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Generar y compartir PDF
              final pdfPath = await _generarPDF();
              await Share.shareXFiles([XFile(pdfPath)], text: 'Factura ${widget.factura["numero"]}');
            },
            child: const Text('PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> _compartirXML() async {
    if (xmlPath == null) {
      final dir = await getApplicationDocumentsDirectory();
      xmlPath = '${dir.path}/${widget.factura["numero"]}.xml';
    }

    final file = File(xmlPath!);
    if (await file.exists()) {
      await Share.shareXFiles([XFile(file.path)], text: 'Factura ${widget.factura["numero"]}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el archivo XML')),
      );
    }
  }

  Future<void> _descargarXML() async {
    if (xmlPath == null) {
      final dir = await getApplicationDocumentsDirectory();
      xmlPath = '${dir.path}/${widget.factura["numero"]}.xml';
    }

    final file = File(xmlPath!);
    if (await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Archivo XML disponible en:\n${file.path}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el archivo XML')),
      );
    }
  }
  Future<String> _generarPDF() async {
    final factura = widget.factura;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Factura: ${factura["numero"]}', style: const pw.TextStyle(fontSize: 18)),
              pw.Text('Cliente: ${factura["cliente"]}'),
              pw.Text('Total: \$${factura["total"]}'),
              pw.Text('Autorizada: ${factura["autorizada"] ? "Sí" : "No"}'),
            ],
          );
        },
      ),
    );


    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${factura["numero"]}.pdf');
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF generado en: ${file.path}')),
    );

    return file.path;
  }
  @override
  Widget build(BuildContext context) {
    final factura = widget.factura;

    return Scaffold(
      appBar: AppBar(title: Text('Detalle de ${factura["numero"]}')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Cliente:", style: Theme.of(context).textTheme.titleMedium),
                Text(factura["cliente"], style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),

                Text("Total:", style: Theme.of(context).textTheme.titleMedium),
                Text("\$${factura["total"].toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),

                Text("Estado XML:", style: Theme.of(context).textTheme.titleMedium),
                Row(
                  children: [
                    Icon(
                      factura["xml"] ? Icons.code : Icons.code_off,
                      color: factura["xml"] ? Colors.green : Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(factura["xml"] ? "Generado" : "No generado"),
                  ],
                ),
                const SizedBox(height: 16),

                Text("Autorizado SRI:", style: Theme.of(context).textTheme.titleMedium),
                Row(
                  children: [
                    Icon(
                      factura["autorizada"] ? Icons.verified : Icons.cancel,
                      color: factura["autorizada"] ? Colors.green : Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(factura["autorizada"] ? "Sí" : "No"),
                  ],
                ),
                const Spacer(),

                // 🔘 Botón dinámico según estado del XML
             
                Center(
                  child: factura["xml"]
                      ? ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Compartir'),
                    onPressed: _preguntarYCompartir,
                  )
                      : ElevatedButton.icon(
                    icon: const Icon(Icons.code),
                    label: const Text('Generar XML'),
                    onPressed: _generarXML,
                  ),
                ),


                const SizedBox(height: 16),
                Center(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
