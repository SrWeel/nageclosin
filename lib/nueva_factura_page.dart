import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NuevaFacturaPage extends StatefulWidget {
  const NuevaFacturaPage({Key? key}) : super(key: key);

  @override
  State<NuevaFacturaPage> createState() => _NuevaFacturaPageState();
}

class _NuevaFacturaPageState extends State<NuevaFacturaPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _rucController = TextEditingController();
  final TextEditingController _razonSocialController = TextEditingController();
  final TextEditingController _estabController = TextEditingController();
  final TextEditingController _ptoEmiController = TextEditingController();
  final TextEditingController _codDocController = TextEditingController();
  final TextEditingController _secuencialController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();

  bool _cargando = false;

  Future<void> _guardarFactura() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    final total = double.tryParse(_totalController.text) ?? 0;
    final now = DateTime.now();
    final fecha =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    final facturaJson = {
      "infoTributaria": {
        "razonSocial": _razonSocialController.text,
        "ruc": _rucController.text,
        "codDoc": _codDocController.text,
        "estab": _estabController.text,
        "ptoEmi": _ptoEmiController.text,
        "secuencial": _secuencialController.text,
        "claveAcceso": "" // El servidor lo genera
      },
      "infoFactura": {
        "fechaEmision": fecha,
        "dirEstablecimiento": "Quito, Ecuador",
        "totalSinImpuestos": total,
        "importeTotal": total * 1.12
      },
      "detalles": [
        {
          "descripcion": "Producto A",
          "cantidad": 1.0,
          "precioUnitario": total,
          "precioTotalSinImpuesto": total
        }
      ]
    };

    try {
      final apiUrl = 'http://192.168.1.19:5110/api/SriFactura/generar-xml';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(facturaJson),
      );

      print('Response: ${response.body}'); // Para depurar

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Usamos la clave de acceso devuelta por el servidor si existe
        final claveAcceso = (data['infoTributaria']?['claveAcceso'] ??
            facturaJson['infoTributaria'] ?? ['secuencial']).toString();

        final nuevaFactura = {
          "numero": claveAcceso,
          "total": total,
          "xml": true,
          "autorizada": false,
          "InfoTributaria": facturaJson["infoTributaria"],
          "xmlPreview": data["xmlPreview"] ?? response.body,
        };

        Navigator.pop(context, nuevaFactura);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar XML: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Factura')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _rucController,
                    decoration: const InputDecoration(labelText: 'RUC', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Ingrese el RUC' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _razonSocialController,
                    decoration: const InputDecoration(labelText: 'Razón Social', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Ingrese la razón social' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _estabController,
                    decoration: const InputDecoration(labelText: 'Establecimiento', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Ingrese el código de establecimiento' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ptoEmiController,
                    decoration: const InputDecoration(labelText: 'Punto de Emisión', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Ingrese el punto de emisión' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _codDocController,
                    decoration: const InputDecoration(labelText: 'Código de Documento', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Ingrese el código de documento' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _secuencialController,
                    decoration: const InputDecoration(labelText: 'Secuencial', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Ingrese el número secuencial' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _totalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Total', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Ingrese el total' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _guardarFactura,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Factura'),
                  ),
                ],
              ),
            ),
          ),
          if (_cargando)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
