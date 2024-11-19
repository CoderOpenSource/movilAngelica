import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CrearEditarHistorialScreen extends StatefulWidget {
  final Map<String, dynamic>? historial;
  final Function? onSuccess;

  const CrearEditarHistorialScreen({super.key, this.historial, this.onSuccess});

  @override
  _CrearEditarHistorialScreenState createState() =>
      _CrearEditarHistorialScreenState();
}

class _CrearEditarHistorialScreenState
    extends State<CrearEditarHistorialScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _fechaInicio;
  String _comentariosGenerales = '';

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.historial != null) {
      _fechaInicio = DateTime.parse(widget.historial!['fechaInicio']);
      _comentariosGenerales = widget.historial!['comentariosGenerales'] ?? '';
    }
  }

  Future<void> _guardarHistorial() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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

    final url = widget.historial == null
        ? Uri.parse('http://64.23.217.187/api/historiales')
        : Uri.parse(
            'http://64.23.217.187/api/historiales/${widget.historial!['id']}');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'fechaInicio': _fechaInicio?.toIso8601String(),
      'comentariosGenerales': _comentariosGenerales,
    });

    try {
      final response = widget.historial == null
          ? await http.post(url, headers: headers, body: body)
          : await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onSuccess?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Historial clínico ${widget.historial == null ? "creado" : "actualizado"} exitosamente')),
        );
      } else {
        setState(() {
          _errorMessage =
              'Error: ${response.statusCode}. No se pudo ${widget.historial == null ? "crear" : "actualizar"} el historial clínico.';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = "Error de red: $error";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _seleccionarFechaInicio(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _fechaInicio) {
      setState(() {
        _fechaInicio = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.historial == null ? 'Crear Historial' : 'Editar Historial'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                title: Text(_fechaInicio == null
                    ? 'Seleccionar Fecha de Inicio'
                    : 'Fecha de Inicio: ${_fechaInicio!.toLocal()}'
                        .split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _seleccionarFechaInicio(context),
              ),
              TextFormField(
                initialValue: _comentariosGenerales,
                decoration:
                    const InputDecoration(labelText: 'Comentarios Generales'),
                maxLines: 3,
                onChanged: (value) => _comentariosGenerales = value,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _guardarHistorial,
                  child: Text(
                      widget.historial == null ? 'Crear' : 'Guardar cambios'),
                ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
