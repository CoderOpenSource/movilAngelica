import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/widgets/app_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mapas_api/widgets/sesion_expirada_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class HistorialClinicoScreen extends StatefulWidget {
  const HistorialClinicoScreen({super.key});

  @override
  _HistorialClinicoScreenState createState() => _HistorialClinicoScreenState();
}

class _HistorialClinicoScreenState extends State<HistorialClinicoScreen> {
  int? _userId;
  int? _pacienteId;
  Future<HistorialClinico>? _historialClinico;

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
        _historialClinico = fetchHistorialClinico(token);
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
            print('PACIENTE ID ${paciente['id']}');
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

  Future<HistorialClinico> fetchHistorialClinico(String? token) async {
    if (_pacienteId == null) {
      throw Exception('Paciente no encontrado');
    }

    final response = await http.get(
      Uri.parse(
          'http://143.198.147.110/api/historiales-clinicos/paciente/$_pacienteId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return HistorialClinico.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      SessionExpiredModal.show(context); // Mostrar modal de sesión expirada
      throw Exception('Sesión expirada');
    } else {
      throw Exception('Error al cargar el historial clínico');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial Clínico'),
        backgroundColor: const Color(0xFF1E272E),
      ),
      drawer: AppDrawer(),
      body: FutureBuilder<HistorialClinico>(
        future: _historialClinico,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(
                child: Text('No se encontró historial clínico.'));
          } else {
            final historial = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: const Color(0xFF1E272E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text(
                    'Historial de ${historial.pacienteNombre}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha de creación: ${historial.fechaCreacion}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Última actualización: ${historial.fechaUltimaActualizacion}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Notas: ${historial.notas ?? "Sin notas"}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  trailing: historial.archivoUrl != null
                      ? ElevatedButton(
                          onPressed: () {
                            _abrirArchivoEnNavegador(historial.archivoUrl!);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                          child: const Text(
                            'Ver Archivo',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : const Text(
                          'Sin Archivo',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _abrirArchivoEnNavegador(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw Exception('No se puede abrir el archivo');
    }
  }
}

class HistorialClinico {
  final int id;
  final int pacienteId;
  final String pacienteNombre;
  final String fechaCreacion;
  final String fechaUltimaActualizacion;
  final String? notas;
  final String? archivoUrl;

  HistorialClinico({
    required this.id,
    required this.pacienteId,
    required this.pacienteNombre,
    required this.fechaCreacion,
    required this.fechaUltimaActualizacion,
    this.notas,
    this.archivoUrl,
  });

  factory HistorialClinico.fromJson(Map<String, dynamic> json) {
    return HistorialClinico(
      id: json['id'],
      pacienteId: json['pacienteId'],
      pacienteNombre: json['pacienteNombre'],
      fechaCreacion: json['fechaCreacion'],
      fechaUltimaActualizacion: json['fechaUltimaActualizacion'],
      notas: json['notas'],
      archivoUrl: json['archivoUrl'],
    );
  }
}
