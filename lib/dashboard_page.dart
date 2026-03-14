import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'facturas_page.dart';
import 'clientes_page.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class Empresa {
  final String nombre;
  final String ruc;
  final String direccion;
  final double pagoMinimo;

  Empresa({
    required this.nombre,
    required this.ruc,
    required this.direccion,
    required this.pagoMinimo,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      nombre: json['nombre'] ?? '',
      ruc: json['ruc'] ?? '',
      direccion: json['direccion'] ?? '',
      pagoMinimo: (json['pagoMinimo'] ?? 0).toDouble(),
    );
  }
}

class Subscription {
  final String id;
  final int mesesRestantes;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool activo;
  final String plan;
  final double monto;

  Subscription({
    required this.id,
    required this.mesesRestantes,
    required this.fechaInicio,
    required this.fechaFin,
    required this.activo,
    required this.plan,
    required this.monto,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? '',
      mesesRestantes: json['mesesRestantes'] ?? 0,
      fechaInicio: DateTime.parse(json['fechaInicio']),
      fechaFin: DateTime.parse(json['fechaFin']),
      activo: json['activo'] ?? false,
      plan: json['plan'] ?? 'Sin plan',
      monto: (json['monto'] ?? 0).toDouble(),
    );
  }
}

class DashboardData {
  final Empresa empresa;
  final Subscription suscripcion;

  DashboardData({
    required this.empresa,
    required this.suscripcion,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      empresa: Empresa.fromJson(json['empresa']),
      suscripcion: Subscription.fromJson(json['suscripcion']),
    );
  }
}

class _DashboardPageState extends State<DashboardPage> {
  List<DashboardData> _empresasData = [];
  int _empresaSeleccionadaIndex = 0;
  bool _loadingSubscription = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() {
      _loadingSubscription = true;
      _errorMessage = null;
    });

    try {
      final data = await fetchSubscription();
      setState(() {
        _empresasData = data;
        _loadingSubscription = false;
        // Si hay empresas, seleccionar la primera
        if (_empresasData.isNotEmpty) {
          _empresaSeleccionadaIndex = 0;
        }
      });
    } catch (e) {
      setState(() {
        _loadingSubscription = false;
        _errorMessage = e.toString();
      });
      print('Error loading subscription: $e');
    }
  }

  Future<List<DashboardData>> fetchSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('Token encontrado: ${token != null}');

      if (token == null) {
        throw Exception('No se encontró token de autenticación');
      }

      // IMPORTANTE: Cambia esta IP por la correcta de tu servidor
      final url = Uri.parse('http://192.168.1.19:5000/api/auth/suscripcion');

      print('Haciendo petición a: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no respondió');
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Si la respuesta es un objeto único, lo convertimos en lista
        if (responseData is Map<String, dynamic>) {
          return [DashboardData.fromJson(responseData)];
        }
        // Si la respuesta es una lista de empresas
        else if (responseData is List) {
          return responseData
              .map((item) => DashboardData.fromJson(item))
              .toList();
        } else {
          throw Exception('Formato de respuesta inesperado');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else if (response.statusCode == 404) {
        throw Exception('No hay suscripción activa');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en fetchSubscription: $e');
      rethrow;
    }
  }

  Future<void> _handleRefresh() async {
    await _loadSubscription();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'Dashboard actualizado'),
          duration: const Duration(seconds: 2),
          backgroundColor: _errorMessage != null ? Colors.red : null,
        ),
      );
    }
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');

              if (!mounted) return;
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
              );
            },
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  DashboardData? get _currentData {
    if (_empresasData.isEmpty || _empresaSeleccionadaIndex >= _empresasData.length) {
      return null;
    }
    return _empresasData[_empresaSeleccionadaIndex];
  }

  @override
  Widget build(BuildContext context) {
    final currentData = _currentData;
    final showDropdown = _empresasData.length > 1;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: showDropdown
            ? Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _empresaSeleccionadaIndex,
                  icon: const Icon(CupertinoIcons.chevron_down, size: 14),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _empresaSeleccionadaIndex = newValue;
                      });
                    }
                  },
                  items: _empresasData
                      .asMap()
                      .entries
                      .map<DropdownMenuItem<int>>((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value.empresa.nombre),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        )
            : null,
        leadingWidth: showDropdown ? 140 : null,
        title: Text(
          currentData?.empresa.nombre ?? 'Cargando...',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_arrow_right, size: 22),
            tooltip: 'Cerrar Sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Card de Suscripción
                if (_loadingSubscription)
                  Container(
                    height: 150,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: CupertinoActivityIndicator(),
                    ),
                  )
                else if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.exclamationmark_triangle,
                            color: Colors.red[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Error al cargar suscripción',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.refresh),
                          onPressed: _loadSubscription,
                        ),
                      ],
                    ),
                  )
                else if (currentData != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: _DashboardCard(
                        icon: CupertinoIcons.clock,
                        label: '${currentData.suscripcion.plan}: ${currentData.suscripcion.mesesRestantes} meses',
                        color: Colors.teal,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => CupertinoAlertDialog(
                              title: const Text('Detalles de suscripción'),
                              content: Text(
                                  'Plan: ${currentData.suscripcion.plan}\n'
                                      'Inicio: ${currentData.suscripcion.fechaInicio.toLocal().toString().split(" ")[0]}\n'
                                      'Fin: ${currentData.suscripcion.fechaFin.toLocal().toString().split(" ")[0]}\n'
                                      'Activo: ${currentData.suscripcion.activo ? "Sí" : "No"}\n'
                                      'Meses restantes: ${currentData.suscripcion.mesesRestantes}\n'
                                      'Monto: \$${currentData.suscripcion.monto.toStringAsFixed(2)}'),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('Cerrar'),
                                  onPressed: () => Navigator.pop(context),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                // Grid de opciones
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    _DashboardCard(
                      icon: CupertinoIcons.doc_text,
                      label: 'Facturas',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const FacturasPage()),
                        );
                      },
                    ),
                    _DashboardCard(
                      icon: CupertinoIcons.person_2,
                      label: 'Clientes',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ClientesPage()),
                        );
                      },
                    ),
                    _DashboardCard(
                      icon: CupertinoIcons.cube_box,
                      label: 'Productos',
                      color: Colors.orange,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Abrir Productos')),
                        );
                      },
                    ),
                    _DashboardCard(
                      icon: CupertinoIcons.chart_bar,
                      label: 'Reportes',
                      color: Colors.green,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Abrir Reportes')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}