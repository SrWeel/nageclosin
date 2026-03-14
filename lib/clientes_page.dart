import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;

class ClientesPage extends StatefulWidget {
  const ClientesPage({Key? key}) : super(key: key);

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  List<dynamic> clientes = [];
  bool isLoading = true;
  final apiUrl = 'http://192.168.1.19:5110/api/SriFactura/clientes';

  @override
  void initState() {
    super.initState();
    fetchClientes();
  }

  Future<void> fetchClientes() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          clientes = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener clientes');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _abrirFormularioNuevoCliente({Map<String, dynamic>? cliente}) async {
    final registrado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistrarClientePage(cliente: cliente),
      ),
    );

    if (registrado == true) fetchClientes();
  }

  Future<void> eliminarCliente(String id) async {
    try {
      final response = await http.delete(Uri.parse('$apiUrl/$id'));
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() => clientes.removeWhere((c) => c['id'].toString() == id));
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cliente eliminado')));
      } else {
        throw Exception('Error: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes Registrados')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : clientes.isEmpty
          ? const Center(child: Text('No hay clientes registrados'))
          : RefreshIndicator(
        onRefresh: fetchClientes,
        child: ListView.builder(
          itemCount: clientes.length,
          itemBuilder: (context, index) {
            final cliente = clientes[index];
            return Slidable(
              key: ValueKey(cliente['id']),
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) => _abrirFormularioNuevoCliente(
                        cliente: cliente), // editar
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: 'Editar',
                  ),
                  SlidableAction(
                    onPressed: (context) => eliminarCliente(
                        cliente['id'].toString()), // eliminar
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Eliminar',
                  ),
                ],
              ),
              child: Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                child: ListTile(
                  leading:
                  const Icon(Icons.person, color: Colors.black),
                  title: Text(cliente['nombre']?.toString() ?? ''),
                  subtitle: Text(
                    'CI/RUC: ${cliente['identificacion']?.toString() ?? ''}\n'
                        'Email: ${cliente['email']?.toString() ?? ''}',
                  ),
                  isThreeLine: true,
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormularioNuevoCliente(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class RegistrarClientePage extends StatefulWidget {
  final Map<String, dynamic>? cliente;
  const RegistrarClientePage({Key? key, this.cliente}) : super(key: key);

  @override
  State<RegistrarClientePage> createState() => _RegistrarClientePageState();
}

class _RegistrarClientePageState extends State<RegistrarClientePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController identificacionCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  bool isSaving = false;
  late bool isEdit;
  final apiUrl = 'http://192.168.1.19:5110/api/SriFactura/clientes';

  @override
  void initState() {
    super.initState();
    isEdit = widget.cliente != null;

    if (isEdit) {
      nombreCtrl.text = widget.cliente?['nombre'] ?? '';
      identificacionCtrl.text = widget.cliente?['identificacion'] ?? '';
      emailCtrl.text = widget.cliente?['email'] ?? '';
    }
  }

  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);

    final body = jsonEncode({
      'nombre': nombreCtrl.text,
      'identificacion': identificacionCtrl.text,
      'email': emailCtrl.text,
    });

    try {
      late http.Response response;

      if (isEdit) {
        final id = widget.cliente?['id'];
        response = await http.put(
          Uri.parse('$apiUrl/$id'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
      } else {
        response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
      }

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: Text(isEdit ? 'Editar Cliente' : 'Nuevo Cliente')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.isEmpty ? 'Ingrese el nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: identificacionCtrl,
                decoration: const InputDecoration(
                  labelText: 'CI o RUC',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.isEmpty ? 'Ingrese la identificación' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || !v.contains('@') ? 'Correo inválido' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _guardarCliente,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    isEdit ? 'Actualizar Cliente' : 'Guardar Cliente',
                    style: const TextStyle(color: Colors.white),
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
