import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/screens/pacientes/crear_editar_antecedentes_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class VerAntecedentesScreen extends StatefulWidget {
  final int userId;

  const VerAntecedentesScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  _VerAntecedentesScreenState createState() => _VerAntecedentesScreenState();
}

class _VerAntecedentesScreenState extends State<VerAntecedentesScreen> {
  List<dynamic> antecedentes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAntecedentes();
  }

  Future<void> _fetchAntecedentes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;

    final url = Uri.parse(
        'http://64.23.217.187/api/antecedentesREST/usuario/${widget.userId}');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        setState(() {
          antecedentes = jsonDecode(utf8.decode(response.bodyBytes));
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error de red: $error";
      });
    }
  }

  void _navigateToCrearEditarAntecedente(
      {Map<String, dynamic>? antecedente}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearEditarAntecedenteScreen(
          antecedente: antecedente,
          userId: widget.userId,
          onSuccess: _fetchAntecedentes,
        ),
      ),
    );
  }

  Future<void> _eliminarAntecedente(int antecedenteId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;

    final url =
        Uri.parse('http://64.23.217.187/api/antecedentesREST/$antecedenteId');
    try {
      final response =
          await http.delete(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 204) _fetchAntecedentes();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar antecedente')),
      );
    }
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antecedentes del Paciente'),
        backgroundColor: const Color(0xFF1E272E),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCrearEditarAntecedente(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : antecedentes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning,
                              color: Colors.orange, size: 60),
                          const SizedBox(height: 10),
                          const Text(
                            'No se encontraron antecedentes',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () =>
                                _navigateToCrearEditarAntecedente(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E272E),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Crear Antecedente',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: antecedentes.length,
                      itemBuilder: (context, index) {
                        final antecedente = antecedentes[index];
                        return _buildAntecedenteCard(antecedente);
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCrearEditarAntecedente(),
        backgroundColor: const Color(0xFF1E272E),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAntecedenteCard(Map<String, dynamic> antecedente) {
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
          children: [
            if (antecedente['tipo'] != null)
              Text(
                'Tipo: ${antecedente['tipo']}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            const SizedBox(height: 8),
            if (antecedente['descripcion'] != null)
              Text(
                'Descripción: ${antecedente['descripcion']}',
                style: TextStyle(color: Colors.grey[300]),
              ),
            if (antecedente['fechaInicio'] != null)
              Text(
                'Fecha Inicio: ${_formatDate(antecedente['fechaInicio'])}',
                style: TextStyle(color: Colors.grey[300]),
              ),
            if (antecedente['fechaDiagnostico'] != null)
              Text(
                'Fecha Diagnóstico: ${_formatDate(antecedente['fechaDiagnostico'])}',
                style: TextStyle(color: Colors.grey[300]),
              ),
            if (antecedente['frecuencia'] != null)
              Text(
                'Frecuencia: ${antecedente['frecuencia']}',
                style: TextStyle(color: Colors.grey[300]),
              ),
            if (antecedente['parentesco'] != null)
              Text(
                'Parentesco: ${antecedente['parentesco']}',
                style: TextStyle(color: Colors.grey[300]),
              ),
            if (antecedente['tratamientoActual'] != null)
              Text(
                'Tratamiento Actual: ${antecedente['tratamientoActual']}',
                style: TextStyle(color: Colors.grey[300]),
              ),
            if (antecedente['estado'] != null)
              Text(
                'Estado: ${antecedente['estado']}',
                style: TextStyle(color: Colors.grey[300]),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _navigateToCrearEditarAntecedente(
                      antecedente: antecedente),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarAntecedente(antecedente['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
