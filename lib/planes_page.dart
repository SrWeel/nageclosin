import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PlanesPage extends StatefulWidget {
  const PlanesPage({super.key});

  @override
  State<PlanesPage> createState() => _PlanesPageState();
}

class _PlanesPageState extends State<PlanesPage> {
  Map<String, dynamic>? userData;
  bool loading = true;
  List<String> selectedExtras = [];

  @override
  void initState() {
    super.initState();
    fetchPlanes();
  }

  Future<void> fetchPlanes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          loading = false;
          userData = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el token. Inicia sesión nuevamente.')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.1.19:5000/api/auth/estado-usuario'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body);
          loading = false;
        });
      } else {
        debugPrint('Error ${response.statusCode}: ${response.body}');
        setState(() => loading = false);
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => loading = false);
    }
  }

  double calcularPrecioFinal() {
    double total = 0;

    // Plan actual
    if (userData != null && userData!['suscripcionActual'] != null) {
      total += (userData!['suscripcionActual']['plan']['monto'] ?? 0).toDouble();
    }

    // Planes extras seleccionados
    if (userData != null) {
      for (var plan in userData!['otrosPlanes']) {
        if (selectedExtras.contains(plan['id'])) {
          total += (plan['monto'] ?? 0).toDouble();
        }
      }
    }

    return total;
  }

  Future<void> procesarPago() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final extrasIds = selectedExtras;

    final response = await http.post(
      Uri.parse('http://192.168.1.19:5000/api/suscripcion/cambiar-plan'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'extras': extrasIds}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago realizado correctamente ✅')),
      );
      fetchPlanes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar el pago: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userData == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Error al cargar los datos del usuario.',
            style: TextStyle(color: Colors.red[600]),
          ),
        ),
      );
    }

    final usuario = userData!['usuario'];
    final suscripcionActual = userData!['suscripcionActual'];
    final otrosPlanes = userData!['otrosPlanes'] as List<dynamic>;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Planes Premium',
          style: TextStyle(fontFamily: 'San Francisco', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Usuario
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // 🔹 Icono de estado
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: usuario['activo'] ? Colors.green : Colors.red,
                        child: Icon(
                          usuario['activo'] ? Icons.check : Icons.lock,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 🔹 Nombre y email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              usuario['username'],
                              style: const TextStyle(
                                fontFamily: 'San Francisco',
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              usuario['email'],
                              style: const TextStyle(
                                fontFamily: 'San Francisco',
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 🔹 Estado como texto profesional
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        decoration: BoxDecoration(
                          color: usuario['activo'] ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          usuario['activo'] ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            color: usuario['activo'] ? Colors.green[800] : Colors.red[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),


              const SizedBox(height: 20),

              // Suscripción actual
              if (suscripcionActual != null) ...[
                Text(
                  "Tu plan actual",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  child: ListTile(
                    title: Text(
                      suscripcionActual['plan']['nombre'],
                      style: const TextStyle(
                        fontFamily: 'San Francisco',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      "Precio: \$${suscripcionActual['plan']['monto']} | "
                          "Periodo: ${suscripcionActual['plan']['periodoMeses']} meses",
                      style: const TextStyle(fontFamily: 'San Francisco', fontSize: 14, color: Colors.black54),
                    ),
                    trailing: const Icon(Icons.star, color: Colors.indigo, size: 32),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Planes opcionales
              Text(
                "Opciones adicionales",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              ...otrosPlanes.map((plan) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: CheckboxListTile(
                    value: selectedExtras.contains(plan['id']),
                    onChanged: (val) {
                      setState(() {
                        if (val!) {
                          selectedExtras.add(plan['id']);
                        } else {
                          selectedExtras.remove(plan['id']);
                        }
                      });
                    },
                    title: Text(
                      plan['nombre'],
                      style: const TextStyle(
                        fontFamily: 'San Francisco',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      "Precio: \$${plan['monto']} | Periodo: ${plan['periodoMeses']} meses",
                      style: const TextStyle(fontFamily: 'San Francisco', fontSize: 14, color: Colors.black54),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              // Resumen precio final
              Card(
                color: Colors.indigo[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Precio final",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'San Francisco',
                        ),
                      ),
                      Text(
                        "\$${calcularPrecioFinal().toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'San Francisco',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botón pagar
              Center(
                child: ElevatedButton(
                  onPressed: () => procesarPago(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[800],
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                  ),
                  child: Text(
                    "Pagar ahora",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'San Francisco',
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
