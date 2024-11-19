import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/widgets/app_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'crear_editar_especialidad_screen.dart'; // Ruta correcta para la pantalla de creación/edición de especialidades

class ListarEspecialidadesScreen extends StatefulWidget {
  const ListarEspecialidadesScreen({super.key});

  @override
  _ListarEspecialidadesScreenState createState() =>
      _ListarEspecialidadesScreenState();
}

class _ListarEspecialidadesScreenState
    extends State<ListarEspecialidadesScreen> {
  List<dynamic> especialidades = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEspecialidades();
  }

  // Obtener la lista de especialidades
  Future<void> _fetchEspecialidades() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "No se encontró el token de autenticación.";
      });
      return;
    }

    final url = Uri.parse('http://64.23.217.187/api/especialidades');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          especialidades = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Error: ${response.statusCode}. No se pudo cargar la lista de especialidades.";
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error de red: $error";
      });
    }
  }

  // Eliminar una especialidad
  Future<void> _eliminarEspecialidad(int especialidadId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      setState(() {
        _errorMessage = "No se encontró el token de autenticación.";
      });
      return;
    }

    final url =
        Uri.parse('http://64.23.217.187/api/especialidades/$especialidadId');

    try {
      final response = await http.delete(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 204) {
        setState(() {
          especialidades.removeWhere((item) => item['id'] == especialidadId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Especialidad eliminada exitosamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error: ${response.statusCode}. No se pudo eliminar la especialidad.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de red: $error')),
      );
    }
  }

  // Navegar a la pantalla de crear o editar especialidad
  void _navigateToCrearEditarEspecialidad(
      {Map<String, dynamic>? especialidad}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearEditarEspecialidadScreen(
          especialidad: especialidad,
          onSuccess:
              _fetchEspecialidades, // Recargar la lista después de crear/editar
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Especialidades'),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: especialidades.length,
                  itemBuilder: (context, index) {
                    final especialidad = especialidades[index];
                    return _buildEspecialidadCard(especialidad);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCrearEditarEspecialidad(),
        backgroundColor: const Color(0xFF1E272E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Construir la tarjeta para cada especialidad
  Widget _buildEspecialidadCard(Map<String, dynamic> especialidad) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              especialidad['name'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Descripción: ${especialidad['descripcion']}',
                style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _navigateToCrearEditarEspecialidad(
                      especialidad: especialidad),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarEspecialidad(especialidad['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
