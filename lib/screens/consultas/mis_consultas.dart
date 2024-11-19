import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/widgets/app_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mapas_api/widgets/sesion_expirada_widget.dart';

class MisConsultasScreen extends StatefulWidget {
  const MisConsultasScreen({super.key});

  @override
  _MisConsultasScreenState createState() => _MisConsultasScreenState();
}

class _MisConsultasScreenState extends State<MisConsultasScreen> {
  int? _userId;
  int? _pacienteId;
  Future<List<Consulta>>? _consultas;

  @override
  void initState() {
    super.initState();
    obtenerUserId();
  }

  Future<void> obtenerUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('accessToken');

    setState(() {
      _userId = prefs.getInt('userId');
    });

    if (_userId != null) {
      await fetchPacienteId(token);
      setState(() {
        _consultas = fetchConsultas(token);
      });
    }
  }

  Future<void> fetchPacienteId(String? token) async {
    final response = await http.get(
      Uri.parse('http://143.198.147.110/api/pacientes'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      for (var paciente in jsonList) {
        if (paciente['usuario']['id'] == _userId) {
          setState(() {
            _pacienteId = paciente['id'];
          });
          break;
        }
      }
    } else if (response.statusCode == 401) {
      SessionExpiredModal.show(context); // Mostrar modal de sesión expirada
    } else {
      throw Exception('Error al cargar los pacientes');
    }
  }

  Future<List<Consulta>> fetchConsultas(String? token) async {
    final response = await http.get(
      Uri.parse('http://143.198.147.110/api/consultas'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);

      // Filtrar consultas por pacienteId
      final List<Consulta> todasConsultas =
          jsonList.map((json) => Consulta.fromJson(json)).toList();
      final List<Consulta> consultasFiltradas = todasConsultas
          .where((consulta) => consulta.pacienteId == _pacienteId)
          .toList();

      return consultasFiltradas;
    } else if (response.statusCode == 401) {
      SessionExpiredModal.show(context); // Mostrar modal de sesión expirada
      throw Exception('Sesión expirada');
    } else {
      throw Exception('Error al cargar las consultas');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Consultas'),
        backgroundColor: const Color(0xFF1E272E),
      ),
      drawer: AppDrawer(),
      body: FutureBuilder<List<Consulta>>(
        future: _consultas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se encontraron consultas.'));
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final consulta = snapshot.data![index];
                return Card(
                  color: const Color(0xFF1E272E),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: const Icon(Icons.medical_services,
                        color: Colors.blueAccent, size: 40),
                    title: Text(
                      '${consulta.fecha}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Doctor: ${consulta.nombreMedico}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Especialidad: ${consulta.especialidadNombre}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Diagnóstico: ${consulta.diagnostico}',
                          style: TextStyle(color: Colors.white),
                        ),
                        if (consulta.tratamiento != null)
                          Text(
                            'Tratamiento: ${consulta.tratamiento}',
                            style: TextStyle(color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class Consulta {
  final int id;
  final int citaId;
  final int pacienteId;
  final String pacienteNombre;
  final int medicoId;
  final String fecha;
  final String nombreMedico;
  final String diagnostico;
  final List<String>? sintomas;
  final String? tratamiento;
  final String notas;
  final bool derivoProcedimiento;
  final int especialidadId;
  final String especialidadNombre;

  Consulta({
    required this.id,
    required this.citaId,
    required this.pacienteId,
    required this.pacienteNombre,
    required this.medicoId,
    required this.nombreMedico,
    required this.diagnostico,
    required this.fecha,
    this.sintomas,
    this.tratamiento,
    required this.notas,
    required this.derivoProcedimiento,
    required this.especialidadId,
    required this.especialidadNombre,
  });

  factory Consulta.fromJson(Map<String, dynamic> json) {
    return Consulta(
      id: json['id'],
      citaId: json['citaId'],
      fecha: json['fecha'],
      pacienteId: json['pacienteId'],
      pacienteNombre: json['pacienteNombre'],
      medicoId: json['medicoId'],
      nombreMedico: json['nombreMedico'],
      diagnostico: json['diagnostico'],
      sintomas: (json['sintomas'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      tratamiento: json['tratamiento'],
      notas: json['notas'],
      derivoProcedimiento: json['derivoProcedimiento'],
      especialidadId: json['especialidadId'],
      especialidadNombre: json['especialidadNombre'],
    );
  }
}
