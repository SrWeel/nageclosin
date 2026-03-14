import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'detalle_factura_page.dart';
import 'nueva_factura_page.dart';

class FacturasPage extends StatefulWidget {
  const FacturasPage({Key? key}) : super(key: key);

  @override
  State<FacturasPage> createState() => _FacturasPageState();
}

class _FacturasPageState extends State<FacturasPage> {
  List<Map<String, dynamic>> facturas = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarFacturas();
  }

  Future<void> _cargarFacturas() async {
    try {
      final apiUrl = 'http://192.168.1.19:5110/api/SriFactura/listar';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          facturas = data.map<Map<String, dynamic>>((item) {
            return {
              "id": item["id"],
              "numero": item["claveAcceso"],
              "cliente": _extraerRazonSocial(item["xmlPreview"]),
              "total": 0.0, // si tu API no devuelve total
              "xml": true,
              "autorizada": item["soapResponse"] != null,
              "xmlPreview": item["xmlPreview"],
            };
          }).toList();
          cargando = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar facturas: ${response.statusCode}')),
        );
        setState(() => cargando = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
      setState(() => cargando = false);
    }
  }

  String _extraerRazonSocial(String xml) {
    final regex = RegExp(r'<razonSocial>(.*?)<\/razonSocial>');
    final match = regex.firstMatch(xml);
    return match != null ? match.group(1)! : "Desconocido";
  }

  void _agregarFactura(Map<String, dynamic> nuevaFactura) {
    setState(() {
      facturas.add(nuevaFactura);
    });
  }

  Future<void> _generarXML() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando XML de las facturas...')),
    );

    for (var factura in facturas) {
      try {
        final apiUrl = 'http://192.168.1.19:5110/api/SriFactura/generar-xml';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "claveAcceso": factura["numero"],
            "cliente": factura["cliente"],
            "total": factura["total"]
          }),
        );

        if (response.statusCode == 200) {
          factura["xml"] = true;
          factura["xmlPreview"] = response.body;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al generar XML: ${response.statusCode}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e')),
        );
      }
    }

    setState(() {}); // refresca la lista
  }

  Future<void> _autorizarSRI() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enviando facturas al SRI para autorización...')),
    );

    for (var factura in facturas) {
      if (!factura["xml"]) continue; // solo XML generados

      try {
        final apiUrl = 'http://192.168.1.19:5110/api/SriFactura/enviar-sri';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({"claveAcceso": factura["numero"]}),
        );

        if (response.statusCode == 200) {
          factura["autorizada"] = true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error SRI: ${response.statusCode}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión SRI: $e')),
        );
      }
    }

    setState(() {}); // refresca la lista
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facturas')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : facturas.isEmpty
          ? const Center(child: Text('No hay facturas registradas'))
          : ListView.builder(
        itemCount: facturas.length,
        itemBuilder: (context, index) {
          final factura = facturas[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.blueAccent),
              title: Text(factura["numero"]),
              subtitle: Text("Cliente: ${factura["cliente"]}"),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("\$${factura["total"].toStringAsFixed(2)}"),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        factura["xml"] ? Icons.code : Icons.code_off,
                        color: factura["xml"] ? Colors.green : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        factura["autorizada"] ? Icons.verified : Icons.cancel,
                        color: factura["autorizada"] ? Colors.green : Colors.redAccent,
                        size: 18,
                      ),
                    ],
                  )
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetalleFacturaPage(factura: factura),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        backgroundColor: Colors.blueAccent,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        spacing: 10,
        spaceBetweenChildren: 8,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'Nueva Factura',
            onTap: () async {
              final nuevaFactura = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NuevaFacturaPage()),
              );
              if (nuevaFactura != null) _agregarFactura(nuevaFactura);
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.code),
            label: 'Generar XML',
            onTap: _generarXML,
          ),
          SpeedDialChild(
            child: const Icon(Icons.verified),
            label: 'Autorizar con SRI',
            onTap: _autorizarSRI,
          ),
        ],
      ),
    );
  }
}
