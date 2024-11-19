import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CrearEditarPacienteScreen extends StatefulWidget {
  final Map<String, dynamic>?
      paciente; // Paciente para editar (si es null, es creación)
  final VoidCallback
      onSuccess; // Callback al completar la operación (crear/editar)

  const CrearEditarPacienteScreen(
      {Key? key, this.paciente, required this.onSuccess})
      : super(key: key);

  @override
  _CrearEditarPacienteScreenState createState() =>
      _CrearEditarPacienteScreenState();
}

class _CrearEditarPacienteScreenState extends State<CrearEditarPacienteScreen> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController ciController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.paciente != null) {
      _loadPacienteData(
          widget.paciente!); // Cargar datos del paciente si es edición
    }
  }

  // Cargar los datos del paciente si se va a editar
  void _loadPacienteData(Map<String, dynamic> paciente) {
    setState(() {
      usernameController.text = paciente['username'];
      nameController.text = paciente['name'];
      surnameController.text = paciente['surname'];
      emailController.text = paciente['email'];
      ciController.text = paciente['ci'];
      passwordController.text =
          paciente['ci']; // La contraseña es el CI en la creación/edición
    });
  }

  // Función para crear o editar el paciente
  Future<void> _savePaciente() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken'); // Obtener el token

    if (token == null) {
      _showSnackBar("No se encontró el token de autenticación.");
      return;
    }

    final int? idPaciente = widget.paciente != null
        ? int.parse(widget.paciente!['id'].toString())
        : null;
    final url = widget.paciente == null
        ? 'http://64.23.217.187/api/pacientes' // Crear
        : 'http://64.23.217.187/api/pacientes/$idPaciente'; // Editar

    final Map<String, dynamic> requestBody = {
      'username': usernameController.text,
      'password': ciController.text, // La contraseña es el CI
      'name': nameController.text,
      'surname': surnameController.text,
      'email': emailController.text,
      'ci': ciController.text,
    };

    setState(() {
      _isLoading = true;
    });

    try {
      final response = widget.paciente == null
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
        _showSnackBar("Paciente guardado exitosamente.");
        Navigator.pop(context); // Regresar una pantalla atrás
      } else {
        print(
            'Error al guardar el paciente. Código de estado: ${response.statusCode}');
        print('Cuerpo de la respuesta: ${response.body}');
        _showSnackBar("Error al guardar el paciente");
      }
    } catch (error) {
      print('Error de red al guardar el paciente: $error');
      _showSnackBar("Error de red al guardar el paciente");
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
    final isEditing = widget.paciente != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E272E),
        title: Text(isEditing ? "Editar Paciente" : "Crear Paciente"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: <Widget>[
                  _customTextField(
                      usernameController, 'Usuario', 'Nombre de usuario'),
                  const SizedBox(height: 10),
                  _customTextField(
                      nameController, 'Nombre', 'Nombre del paciente'),
                  const SizedBox(height: 10),
                  _customTextField(
                      surnameController, 'Apellido', 'Apellido del paciente'),
                  const SizedBox(height: 10),
                  _customTextField(
                      emailController, 'Email', 'Correo electrónico'),
                  const SizedBox(height: 10),
                  _customTextField(ciController, 'CI', 'Número de CI'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _savePaciente,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E272E),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      isEditing ? "Actualizar Paciente" : "Crear Paciente",
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
