import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CrearEditarAntecedenteScreen extends StatefulWidget {
  final Map<String, dynamic>?
      antecedente; // Antecedente para editar (si es null, es creación)
  final int userId; // ID del usuario al que pertenece el antecedente
  final VoidCallback
      onSuccess; // Callback al completar la operación (crear/editar)

  const CrearEditarAntecedenteScreen(
      {Key? key,
      this.antecedente,
      required this.userId,
      required this.onSuccess})
      : super(key: key);

  @override
  _CrearEditarAntecedenteScreenState createState() =>
      _CrearEditarAntecedenteScreenState();
}

class _CrearEditarAntecedenteScreenState
    extends State<CrearEditarAntecedenteScreen> {
  TextEditingController descripcionController = TextEditingController();
  TextEditingController fechaInicioController = TextEditingController();
  TextEditingController fechaDiagnosticoController = TextEditingController();
  TextEditingController frecuenciaController = TextEditingController();
  TextEditingController parentescoController = TextEditingController();
  TextEditingController tratamientoActualController = TextEditingController();
  TextEditingController estadoController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? selectedTipo; // Tipo de antecedente seleccionado
  List<String> tiposAntecedentes = [
    "Personal",
    "Familiar",
    "Social"
  ]; // Ejemplo de tipos

  @override
  void initState() {
    super.initState();
    if (widget.antecedente != null) {
      _loadAntecedenteData(
          widget.antecedente!); // Cargar datos del antecedente si es edición
      selectedTipo = widget.antecedente!['tipo'];
    }
  }

  // Cargar los datos del antecedente si se va a editar
  void _loadAntecedenteData(Map<String, dynamic> antecedente) {
    setState(() {
      descripcionController.text = antecedente['descripcion'] ?? '';
      fechaInicioController.text = antecedente['fechaInicio'] ?? '';
      fechaDiagnosticoController.text = antecedente['fechaDiagnostico'] ?? '';
      frecuenciaController.text = antecedente['frecuencia'] ?? '';
      parentescoController.text = antecedente['parentesco'] ?? '';
      tratamientoActualController.text = antecedente['tratamientoActual'] ?? '';
      estadoController.text = antecedente['estado'] ?? '';
    });
  }

  // Función para crear o editar el antecedente
  Future<void> _saveAntecedente() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken'); // Obtener el token

    if (token == null) {
      _showSnackBar("No se encontró el token de autenticación.");
      return;
    }

    final int? idAntecedente = widget.antecedente != null
        ? int.parse(widget.antecedente!['id'].toString())
        : null;
    final url = widget.antecedente == null
        ? 'http://64.23.217.187/api/antecedentesREST/usuario/${widget.userId}' // Crear
        : 'http://64.23.217.187/api/antecedentesREST/$idAntecedente'; // Editar

    final Map<String, dynamic> requestBody = {
      'tipo': selectedTipo,
      'descripcion': descripcionController.text,
      'fechaInicio': fechaInicioController.text,
      'fechaDiagnostico': fechaDiagnosticoController.text,
      'frecuencia': frecuenciaController.text,
      'parentesco': parentescoController.text,
      'tratamientoActual': tratamientoActualController.text,
      'estado': estadoController.text,
    };

    setState(() {
      _isLoading = true;
    });

    try {
      final response = widget.antecedente == null
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
        _showSnackBar("Antecedente guardado exitosamente.");
        Navigator.pop(context); // Regresar una pantalla atrás
      } else {
        print(
            'Error al guardar el antecedente. Código de estado: ${response.statusCode}');
        print('Cuerpo de la respuesta: ${response.body}');
        _showSnackBar("Error al guardar el antecedente");
      }
    } catch (error) {
      print('Error de red al guardar el antecedente: $error');
      _showSnackBar("Error de red al guardar el antecedente");
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

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.antecedente != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E272E),
        title: Text(isEditing ? "Editar Antecedente" : "Crear Antecedente"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: <Widget>[
                  _buildTipoDropdown(),
                  const SizedBox(height: 10),
                  _customTextField(descripcionController, 'Descripción',
                      'Descripción del antecedente'),
                  const SizedBox(height: 10),
                  _customDateField(fechaInicioController, 'Fecha Inicio'),
                  const SizedBox(height: 10),
                  if (selectedTipo == "Familiar" || selectedTipo == "Social")
                    _customDateField(
                        fechaDiagnosticoController, 'Fecha Diagnóstico'),
                  if (selectedTipo == "Familiar" || selectedTipo == "Social")
                    _customTextField(frecuenciaController, 'Frecuencia',
                        'Frecuencia del antecedente'),
                  if (selectedTipo == "Familiar")
                    _customTextField(parentescoController, 'Parentesco',
                        'Parentesco (si aplica)'),
                  if (selectedTipo == "Personal" || selectedTipo == "Social")
                    _customTextField(tratamientoActualController,
                        'Tratamiento Actual', 'Tratamiento actual (si aplica)'),
                  if (selectedTipo == "Personal" ||
                      selectedTipo == "Familiar" ||
                      selectedTipo == "Social")
                    _customTextField(
                        estadoController, 'Estado', 'Estado del antecedente'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveAntecedente,
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
                          ? "Actualizar Antecedente"
                          : "Crear Antecedente",
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTipoDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedTipo,
      items: tiposAntecedentes.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          selectedTipo = newValue;
        });
      },
      decoration: const InputDecoration(
        labelText: 'Tipo de Antecedente',
        border: OutlineInputBorder(),
      ),
    );
  }

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

  Widget _customDateField(TextEditingController controller, String label) {
    return GestureDetector(
      onTap: () => _selectDate(controller),
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'YYYY-MM-DD',
            border: const OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}
