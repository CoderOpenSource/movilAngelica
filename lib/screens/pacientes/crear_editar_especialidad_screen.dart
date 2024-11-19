import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CrearEditarEspecialidadScreen extends StatefulWidget {
  final Map<String, dynamic>?
      especialidad; // Especialidad para editar (si es null, es creación)
  final VoidCallback
      onSuccess; // Callback al completar la operación (crear/editar)

  const CrearEditarEspecialidadScreen(
      {Key? key, this.especialidad, required this.onSuccess})
      : super(key: key);

  @override
  _CrearEditarEspecialidadScreenState createState() =>
      _CrearEditarEspecialidadScreenState();
}

class _CrearEditarEspecialidadScreenState
    extends State<CrearEditarEspecialidadScreen> {
  TextEditingController nombreController = TextEditingController();
  TextEditingController descripcionController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.especialidad != null) {
      _loadEspecialidadData(
          widget.especialidad!); // Cargar datos de especialidad si es edición
    }
  }

  // Cargar los datos de la especialidad si se va a editar
  void _loadEspecialidadData(Map<String, dynamic> especialidad) {
    setState(() {
      nombreController.text = especialidad['name'] ?? '';
      descripcionController.text = especialidad['descripcion'] ?? '';
    });
  }

  // Función para crear o editar la especialidad
  Future<void> _saveEspecialidad() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken'); // Obtener el token

    if (token == null) {
      _showSnackBar("No se encontró el token de autenticación.");
      return;
    }

    final int? idEspecialidad = widget.especialidad != null
        ? int.parse(widget.especialidad!['id'].toString())
        : null;
    final url = widget.especialidad == null
        ? 'http://64.23.217.187/api/especialidades' // Crear
        : 'http://64.23.217.187/api/especialidades/$idEspecialidad'; // Editar

    final Map<String, dynamic> requestBody = {
      'name': nombreController.text,
      'descripcion': descripcionController.text,
    };

    setState(() {
      _isLoading = true;
    });

    try {
      final response = widget.especialidad == null
          ? await http.post(Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode(requestBody))
          : await http.put(Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode(requestBody));

      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onSuccess();
        _showSnackBar("Especialidad guardada exitosamente.");
        Navigator.pop(context); // Regresar una pantalla atrás
      } else {
        _showSnackBar("Error al guardar la especialidad");
      }
    } catch (error) {
      _showSnackBar("Error de red al guardar la especialidad");
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
    final isEditing = widget.especialidad != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E272E),
        title: Text(isEditing ? "Editar Especialidad" : "Crear Especialidad"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: <Widget>[
                  _customTextField(
                      nombreController, 'Nombre', 'Nombre de la especialidad'),
                  const SizedBox(height: 10),
                  _customTextField(descripcionController, 'Descripción',
                      'Descripción de la especialidad'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveEspecialidad,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E272E),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      isEditing
                          ? "Actualizar Especialidad"
                          : "Crear Especialidad",
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Función para crear campos de texto
  Widget _customTextField(
      TextEditingController controller, String label, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
