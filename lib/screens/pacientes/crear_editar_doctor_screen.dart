import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CrearEditarDoctorScreen extends StatefulWidget {
  final Map<String, dynamic>? doctor;
  final VoidCallback onSuccess;

  const CrearEditarDoctorScreen(
      {Key? key, this.doctor, required this.onSuccess})
      : super(key: key);

  @override
  _CrearEditarDoctorScreenState createState() =>
      _CrearEditarDoctorScreenState();
}

class _CrearEditarDoctorScreenState extends State<CrearEditarDoctorScreen> {
  TextEditingController firstnameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  String? selectedEspecialidadId;
  List<dynamic> especialidades = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEspecialidades();
    if (widget.doctor != null) {
      _loadDoctorData(widget.doctor!);
    }
  }

  void _loadDoctorData(Map<String, dynamic> doctor) {
    setState(() {
      firstnameController.text = doctor['firstname'] ?? '';
      usernameController.text = doctor['username'] ?? '';
      passwordController.text = doctor['password'] ?? '';
      selectedEspecialidadId = doctor['especialidad']?['id']?.toString();
    });
  }

  Future<void> _fetchEspecialidades() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;

    final url = Uri.parse('http://64.23.217.187/api/especialidades');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        setState(() {
          especialidades = jsonDecode(response.body);
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = "Error al cargar especialidades: $error";
      });
    }
  }

  Future<void> _saveDoctor() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;

    final doctorId = widget.doctor?['id'];
    final url = doctorId == null
        ? Uri.parse('http://64.23.217.187/api/doctors')
        : Uri.parse('http://64.23.217.187/api/doctors/$doctorId');

    final doctorData = {
      'firstname': firstnameController.text,
      'username': usernameController.text,
      'password': passwordController.text,
      'especialidad': selectedEspecialidadId != null
          ? {'id': int.parse(selectedEspecialidadId!)}
          : null,
    };

    setState(() {
      _isLoading = true;
    });

    try {
      final response = doctorId == null
          ? await http.post(url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(doctorData))
          : await http.put(url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(doctorData));

      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onSuccess();
        Navigator.pop(context);
      } else {
        _showError("Error al guardar el doctor: ${response.body}");
      }
    } catch (error) {
      _showError("Error de red: $error");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.doctor != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Editar Doctor" : "Crear Doctor"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: <Widget>[
                  _buildTextField(
                      firstnameController, 'Nombre', 'Nombre del doctor'),
                  const SizedBox(height: 10),
                  _buildTextField(
                      usernameController, 'Usuario', 'Nombre de usuario'),
                  const SizedBox(height: 10),
                  _buildTextField(
                      passwordController, 'Contraseña', 'Contraseña',
                      obscureText: true),
                  const SizedBox(height: 10),
                  _buildEspecialidadDropdown(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveDoctor,
                    child:
                        Text(isEditing ? "Actualizar Doctor" : "Crear Doctor"),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String hint,
      {bool obscureText = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      obscureText: obscureText,
    );
  }

  Widget _buildEspecialidadDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedEspecialidadId,
      hint: const Text('Seleccionar especialidad'),
      items: especialidades.map((especialidad) {
        return DropdownMenuItem<String>(
          value: especialidad['id'].toString(),
          child: Text(especialidad['name']),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedEspecialidadId = value;
        });
      },
      decoration: const InputDecoration(
        labelText: 'Especialidad',
        border: OutlineInputBorder(),
      ),
    );
  }
}
