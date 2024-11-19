import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/widgets/app_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mapas_api/widgets/sesion_expirada_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class MisAnalisisScreen extends StatefulWidget {
  const MisAnalisisScreen({super.key});

  @override
  _MisAnalisisScreenState createState() => _MisAnalisisScreenState();
}

class _MisAnalisisScreenState extends State<MisAnalisisScreen> {
  int? _userId;
  int? _pacienteId;
  Future<List<Analisis>>? _analisis;

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
        _analisis = fetchAnalisis(token);
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

  Future<List<Analisis>> fetchAnalisis(String? token) async {
    final response = await http.get(
      Uri.parse('http://143.198.147.110/api/analisis'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);

      // Filtrar análisis por pacienteId
      final List<Analisis> todosAnalisis =
          jsonList.map((json) => Analisis.fromJson(json)).toList();
      final List<Analisis> analisisFiltrados = todosAnalisis
          .where((analisis) => analisis.pacienteId == _pacienteId)
          .toList();

      return analisisFiltrados;
    } else if (response.statusCode == 401) {
      SessionExpiredModal.show(context); // Mostrar modal de sesión expirada
      throw Exception('Sesión expirada');
    } else {
      throw Exception('Error al cargar los análisis');
    }
  }

  Future<void> abrirArchivo(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw Exception('No se puede abrir el archivo: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Análisis'),
        backgroundColor: const Color(0xFF1E272E),
      ),
      drawer: AppDrawer(),
      body: FutureBuilder<List<Analisis>>(
        future: _analisis,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se encontraron análisis.'));
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final analisis = snapshot.data![index];
                return Card(
                  color: const Color(0xFF1E272E),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: const Icon(
                      Icons.insert_drive_file,
                      color: Colors.blueAccent,
                      size: 40,
                    ),
                    title: Text(
                      '${analisis.tipoAnalisis} (${analisis.fechaRealizacion})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Doctor: ${analisis.medicoNombre} ${analisis.medicoApellido}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Resultado: ${analisis.resultado}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.open_in_new,
                        color: Colors.white,
                      ),
                      onPressed: () => abrirArchivo(analisis.archivoUrl),
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

class Analisis {
  final int id;
  final int pacienteId;
  final String pacienteNombre;
  final String pacienteApellido;
  final int medicoId;
  final String medicoNombre;
  final String medicoApellido;
  final String tipoAnalisis;
  final String resultado;
  final String fechaRealizacion;
  final String archivoUrl;

  Analisis({
    required this.id,
    required this.pacienteId,
    required this.pacienteNombre,
    required this.pacienteApellido,
    required this.medicoId,
    required this.medicoNombre,
    required this.medicoApellido,
    required this.tipoAnalisis,
    required this.resultado,
    required this.fechaRealizacion,
    required this.archivoUrl,
  });

  factory Analisis.fromJson(Map<String, dynamic> json) {
    return Analisis(
      id: json['id'],
      pacienteId: json['pacienteId'],
      pacienteNombre: json['pacienteNombre'],
      pacienteApellido: json['pacienteApellido'],
      medicoId: json['medicoId'],
      medicoNombre: json['medicoNombre'],
      medicoApellido: json['medicoApellido'],
      tipoAnalisis: json['tipoAnalisis'],
      resultado: json['resultado'],
      fechaRealizacion: json['fechaRealizacion'],
      archivoUrl: json['archivoUrl'],
    );
  }
}
