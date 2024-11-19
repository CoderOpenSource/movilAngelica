import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/screens/pacientes/crear_editar_horarios_screen.dart';
import 'package:mapas_api/widgets/app_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListarHorariosScreen extends StatefulWidget {
  const ListarHorariosScreen({super.key});

  @override
  _ListarHorariosScreenState createState() => _ListarHorariosScreenState();
}

class _ListarHorariosScreenState extends State<ListarHorariosScreen> {
  List<dynamic> horarios = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHorarios();
  }

  // Obtener la lista de horarios
  Future<void> _fetchHorarios() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "No se encontró el token de autenticación.";
      });
      return;
    }

    final url = Uri.parse('http://64.23.217.187/api/v2/horarios');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          horarios = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Error: ${response.statusCode}. No se pudo cargar la lista de horarios.";
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error de red: $error";
      });
    }
  }

  // Eliminar un horario
  Future<void> _eliminarHorario(int horarioId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      setState(() {
        _errorMessage = "No se encontró el token de autenticación.";
      });
      return;
    }

    final url = Uri.parse('http://64.23.217.187/api/v2/horarios/$horarioId');

    try {
      final response = await http.delete(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 204) {
        setState(() {
          horarios.removeWhere((item) => item['id'] == horarioId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horario eliminado exitosamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error: ${response.statusCode}. No se pudo eliminar el horario.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de red: $error')),
      );
    }
  }

  // Navegar a la pantalla de crear o editar horario
  void _navigateToCrearEditarHorario({Map<String, dynamic>? horario}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearEditarHorarioScreen(
          horario: horario,
          onSuccess:
              _fetchHorarios, // Recargar la lista después de crear/editar
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horarios'),
        backgroundColor: const Color(0xFF1E272E),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: horarios.length,
                  itemBuilder: (context, index) {
                    final horario = horarios[index];
                    return _buildHorarioCard(horario);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCrearEditarHorario(),
        backgroundColor: const Color(0xFF1E272E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Construir la tarjeta para cada horario
  Widget _buildHorarioCard(Map<String, dynamic> horario) {
    return Card(
      color: const Color(0xFF2C3A47),
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
              horario['horario'],
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Descripción: ${horario['descripcion']}',
              style: TextStyle(color: Colors.grey[300], fontSize: 15),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () =>
                      _navigateToCrearEditarHorario(horario: horario),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarHorario(horario['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
