import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CrearEditarHorarioScreen extends StatefulWidget {
  final Map<String, dynamic>?
      horario; // Horario para editar (si es null, es creación)
  final VoidCallback
      onSuccess; // Callback al completar la operación (crear/editar)

  const CrearEditarHorarioScreen(
      {Key? key, this.horario, required this.onSuccess})
      : super(key: key);

  @override
  _CrearEditarHorarioScreenState createState() =>
      _CrearEditarHorarioScreenState();
}

class _CrearEditarHorarioScreenState extends State<CrearEditarHorarioScreen> {
  TextEditingController horarioController = TextEditingController();
  TextEditingController descripcionController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.horario != null) {
      _loadHorarioData(
          widget.horario!); // Cargar datos del horario si es edición
    }
  }

  // Cargar los datos del horario si se va a editar
  void _loadHorarioData(Map<String, dynamic> horario) {
    setState(() {
      horarioController.text = horario['horario'] ?? '';
      descripcionController.text = horario['descripcion'] ?? '';
    });
  }

  // Función para crear o editar el horario
  Future<void> _saveHorario() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken'); // Obtener el token

    if (token == null) {
      _showSnackBar("No se encontró el token de autenticación.");
      return;
    }

    final int? idHorario = widget.horario != null
        ? int.parse(widget.horario!['id'].toString())
        : null;
    final url = widget.horario == null
        ? 'http://64.23.217.187/api/v2/horarios' // Crear
        : 'http://64.23.217.187/api/v2/horarios/$idHorario'; // Editar

    final Map<String, dynamic> requestBody = {
      'horario': horarioController.text,
      'descripcion': descripcionController.text,
    };

    setState(() {
      _isLoading = true;
    });

    try {
      final response = widget.horario == null
          ? await http.post(Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode(requestBody))
          : await http.put(Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode(requestBody));

      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onSuccess();
        _showSnackBar("Horario guardado exitosamente.");
        Navigator.pop(context); // Regresar una pantalla atrás
      } else {
        print(
            'Error al guardar el horario. Código de estado: ${response.statusCode}');
        print('Cuerpo de la respuesta: ${response.body}');
        _showSnackBar("Error al guardar el horario");
      }
    } catch (error) {
      print('Error de red al guardar el horario: $error');
      _showSnackBar("Error de red al guardar el horario");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.horario == null ? 'Crear Horario' : 'Editar Horario'),
        backgroundColor: const Color(0xFF1E272E),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _customTextField(
                    controller: horarioController,
                    label: 'Horario',
                    hint: 'Ingrese el horario',
                    icon: Icons.access_time,
                  ),
                  const SizedBox(height: 20),
                  _customTextField(
                    controller: descripcionController,
                    label: 'Descripción',
                    hint: 'Ingrese una descripción',
                    icon: Icons.description,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _saveHorario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E272E),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 40),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Guardar Horario',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Campo de texto personalizado
  Widget _customTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1E272E)),
        labelStyle: const TextStyle(
            color: Color(0xFF1E272E), fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF1E272E), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF1E272E), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      style: const TextStyle(fontSize: 16, color: Colors.black87),
    );
  }
}
