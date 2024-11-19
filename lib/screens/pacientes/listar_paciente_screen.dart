import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'crear_editar_paciente_screen.dart'; // Asegúrate de que la ruta sea correcta
import 'ver_antecedentes_screen.dart'; // Asegúrate de que la ruta sea correcta

class VerPacientesScreen extends StatefulWidget {
  const VerPacientesScreen({super.key});

  @override
  _VerPacientesScreenState createState() => _VerPacientesScreenState();
}

class _VerPacientesScreenState extends State<VerPacientesScreen> {
  List<dynamic> pacientes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPacientes();
  }

  // Obtener la lista de pacientes
  Future<void> _fetchPacientes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "No se encontró el token de autenticación.";
      });
      return;
    }

    final url = Uri.parse('http://64.23.217.187/api/pacientes');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          pacientes = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Error: ${response.statusCode}. No se pudo cargar la lista de pacientes.";
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error de red: $error";
      });
    }
  }

  // Eliminar un paciente
  Future<void> _eliminarPaciente(int pacienteId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      setState(() {
        _errorMessage = "No se encontró el token de autenticación.";
      });
      return;
    }

    final url = Uri.parse('http://64.23.217.187/api/pacientes/$pacienteId');

    try {
      final response = await http.delete(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 204) {
        setState(() {
          pacientes.removeWhere((item) => item['id'] == pacienteId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paciente eliminado exitosamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error: ${response.statusCode}. No se pudo eliminar el paciente.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de red: $error')),
      );
    }
  }

  // Navegar a la pantalla de crear o editar paciente
  void _navigateToCrearEditarPaciente({Map<String, dynamic>? paciente}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearEditarPacienteScreen(
          paciente: paciente,
          onSuccess:
              _fetchPacientes, // Recargar la lista después de crear/editar
        ),
      ),
    );
  }

  // Navegar a la pantalla de ver antecedentes
  void _navigateToVerAntecedentes(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerAntecedentesScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacientes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: pacientes.length,
                  itemBuilder: (context, index) {
                    final paciente = pacientes[index];
                    return _buildPacienteCard(paciente);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCrearEditarPaciente(),
        backgroundColor: const Color(0xFF1E272E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Construir la tarjeta para cada paciente
  Widget _buildPacienteCard(Map<String, dynamic> paciente) {
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
              '${paciente['name']} ${paciente['surname']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Username: ${paciente['username']}',
                style: TextStyle(color: Colors.grey[700])),
            Text('Email: ${paciente['email']}',
                style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_red_eye, color: Colors.green),
                  onPressed: () => _navigateToVerAntecedentes(paciente['id']),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () =>
                      _navigateToCrearEditarPaciente(paciente: paciente),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarPaciente(paciente['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
