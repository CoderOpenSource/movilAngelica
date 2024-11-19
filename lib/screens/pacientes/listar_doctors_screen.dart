import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/widgets/app_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'crear_editar_doctor_screen.dart'; // Ruta correcta para la pantalla de creación/edición de doctores

class ListarDoctoresScreen extends StatefulWidget {
  const ListarDoctoresScreen({super.key});

  @override
  _ListarDoctoresScreenState createState() => _ListarDoctoresScreenState();
}

class _ListarDoctoresScreenState extends State<ListarDoctoresScreen> {
  List<dynamic> doctores = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDoctores();
  }

  // Obtener la lista de doctores
  Future<void> _fetchDoctores() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "No se encontró el token de autenticación.";
      });
      return;
    }

    final url = Uri.parse('http://64.23.217.187/api/doctors');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          doctores = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Error: ${response.statusCode}. No se pudo cargar la lista de doctores.";
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error de red: $error";
      });
    }
  }

  // Eliminar un doctor
  Future<void> _eliminarDoctor(int doctorId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      setState(() {
        _errorMessage = "No se encontró el token de autenticación.";
      });
      return;
    }

    final url = Uri.parse('http://64.23.217.187/api/doctors/$doctorId');

    try {
      final response = await http.delete(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 204) {
        setState(() {
          doctores.removeWhere((item) => item['id'] == doctorId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor eliminado exitosamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error: ${response.statusCode}. No se pudo eliminar el doctor.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de red: $error')),
      );
    }
  }

  // Navegar a la pantalla de crear o editar doctor
  void _navigateToCrearEditarDoctor({Map<String, dynamic>? doctor}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearEditarDoctorScreen(
          doctor: doctor,
          onSuccess:
              _fetchDoctores, // Recargar la lista después de crear/editar
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctores'),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: doctores.length,
                  itemBuilder: (context, index) {
                    final doctor = doctores[index];
                    return _buildDoctorCard(doctor);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCrearEditarDoctor(),
        backgroundColor: const Color(0xFF1E272E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Construir la tarjeta para cada doctor
  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
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
              '${doctor['firstname']} (${doctor['username']})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (doctor['especialidad'] != null)
              Text('Especialidad: ${doctor['especialidad']['name']}',
                  style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _navigateToCrearEditarDoctor(doctor: doctor),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarDoctor(doctor['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
