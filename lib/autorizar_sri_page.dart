import 'package:flutter/material.dart';

class AutorizarSriPage extends StatefulWidget {
  const AutorizarSriPage({Key? key}) : super(key: key);

  @override
  State<AutorizarSriPage> createState() => _AutorizarSriPageState();
}

class _AutorizarSriPageState extends State<AutorizarSriPage> {
  bool _autorizando = false;
  String _mensaje = 'Presione el botón para autorizar las facturas pendientes.';

  void _autorizarConSri() async {
    setState(() {
      _autorizando = true;
      _mensaje = 'Conectando con SRI...';
    });

    // Simula una espera de 2 segundos
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _autorizando = false;
      _mensaje = '3 facturas fueron autorizadas correctamente ✅';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Autorización exitosa con el SRI')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _autorizando ? null : _autorizarConSri,
              icon: const Icon(Icons.cloud_upload),
              label: Text(_autorizando ? 'Autorizando...' : 'Autorizar con SRI'),
            ),
          ],
        ),
      ),
    );
  }
}
