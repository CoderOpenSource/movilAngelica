import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'crear_editar_historial_screen.dart';

class VerHistorialesScreen extends StatefulWidget {
  final int? pacienteId;

  const VerHistorialesScreen({super.key, this.pacienteId});

  @override
  _VerHistorialesScreenState createState() => _VerHistorialesScreenState();
}

class _VerHistorialesScreenState extends State<VerHistorialesScreen> {
  List<dynamic> historiales = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _pacienteId;

  @override
  void initState() {
    super.initState();
    _initializePacienteId();
  }

  // Inicializar el pacienteId desde el widget o SharedPreferences
  Future<void> _initializePacienteId() async {
    if (widget.pacienteId != null) {
      _pacienteId = widget.pacienteId;
      await _savePacienteId(_pacienteId!);
    } else {
      await _loadPacienteId();
    }

    if (_pacienteId != null) {
      _fetchHistoriales(); // Cargar historiales si el pacienteId está disponible
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "No se ha encontrado el ID del paciente.";
      });
    }
  }

  // Guardar el pacienteId en SharedPreferences
  Future<void> _savePacienteId(int pacienteId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pacienteId', pacienteId);
  }

  // Cargar el pacienteId desde SharedPreferences
  Future<void> _loadPacienteId() async {
    final prefs = await SharedPreferences.getInstance();
    final pacienteId = prefs.getInt('pacienteId');

    if (pacienteId != null) {
      setState(() {
        _pacienteId = pacienteId;
      });
    } else {
      print(
          "El pacienteId no se ha guardado correctamente en SharedPreferences");
    }
  }

  // Obtener la lista de historiales para el paciente
  Future<void> _fetchHistoriales() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "No se encontró el token de autenticación.";
      });
      return;
    }

    final url =
        Uri.parse('http://64.23.217.187/api/historiales/paciente/$_pacienteId');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          historiales = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Error: ${response.statusCode}. No se pudo cargar la lista de historiales.";
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error de red: $error";
      });
    }
  }

  // Eliminar un historial clínico
  Future<void> _eliminarHistorial(int historialId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      setState(() {
        _errorMessage = "No se encontró el token de autenticación.";
      });
      return;
    }

    final url = Uri.parse('http://64.23.217.187/api/historiales/$historialId');

    try {
      final response = await http.delete(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 204) {
        setState(() {
          historiales.removeWhere((item) => item['id'] == historialId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Historial eliminado exitosamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error: ${response.statusCode}. No se pudo eliminar el historial.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de red: $error')),
      );
    }
  }

  // Navegar a la pantalla de crear o editar historial
  void _navigateToCrearEditarHistorial(
      {Map<String, dynamic>? historial}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearEditarHistorialScreen(
          historial: historial,
          onSuccess:
              _fetchHistoriales, // Recargar la lista después de crear/editar
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historiales Clínicos'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: historiales.length,
                  itemBuilder: (context, index) {
                    final historial = historiales[index];
                    return _buildHistorialCard(historial);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCrearEditarHistorial(),
        backgroundColor: const Color(0xFF1E272E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Construir la tarjeta para cada historial
  Widget _buildHistorialCard(Map<String, dynamic> historial) {
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
              'Fecha de Inicio: ${historial['fechaInicio']?.split("T")[0] ?? 'No especificada'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Comentarios: ${historial['comentariosGenerales'] ?? 'Sin comentarios'}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () =>
                      _navigateToCrearEditarHistorial(historial: historial),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarHistorial(historial['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
