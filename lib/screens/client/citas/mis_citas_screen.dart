import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/widgets/app_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mapas_api/widgets/sesion_expirada_widget.dart';

class MisCitasScreen extends StatefulWidget {
  const MisCitasScreen({super.key});

  @override
  _MisCitasScreenState createState() => _MisCitasScreenState();
}

class _MisCitasScreenState extends State<MisCitasScreen> {
  int? _userId;
  int? _pacienteId;
  Future<List<Cita>>? _citas;

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
        _citas = fetchCitas(token);
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

  Future<List<Cita>> fetchCitas(String? token) async {
    final response = await http.get(
      Uri.parse('http://143.198.147.110/api/citas'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);

      // Filtrar citas por pacienteId
      final List<Cita> todasCitas =
          jsonList.map((json) => Cita.fromJson(json)).toList();
      final List<Cita> citasFiltradas =
          todasCitas.where((cita) => cita.pacienteId == _pacienteId).toList();

      return citasFiltradas;
    } else if (response.statusCode == 401) {
      SessionExpiredModal.show(context); // Mostrar modal de sesión expirada
      throw Exception('Sesión expirada');
    } else {
      throw Exception('Error al cargar las citas');
    }
  }

  Future<void> cancelarCita(int citaId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('accessToken');

    final response = await http.post(
      Uri.parse('http://143.198.147.110/api/citas/cancelar/paciente'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({"citaId": citaId, "pacienteId": _pacienteId}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita cancelada correctamente')),
      );
      setState(() {
        _citas = fetchCitas(token);
      });
    } else if (response.statusCode == 401) {
      SessionExpiredModal.show(context); // Mostrar modal de sesión expirada
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cancelar la cita')),
      );
    }
  }

  bool puedeCancelar(Cita cita) {
    // Verificar si el estado es cancelada o atendida
    if (cita.estado.toLowerCase() == 'cancelada' ||
        cita.estado.toLowerCase() == 'atendida') {
      return false;
    }

    // Verificar si la fecha y hora ya pasaron
    final now = DateTime.now();
    final citaFechaHora = DateTime.parse('${cita.fecha} ${cita.hora}');
    if (now.isAfter(citaFechaHora)) {
      return false;
    }

    return cita.estado.toLowerCase() == 'aceptado';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas'),
        backgroundColor: const Color(0xFF1E272E),
      ),
      drawer: AppDrawer(),
      body: FutureBuilder<List<Cita>>(
        future: _citas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se encontraron citas.'));
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final cita = snapshot.data![index];
                return Card(
                  color: const Color(0xFF1E272E),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        cita.medicoNombre[0], // Inicial del nombre del médico
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      '${cita.fecha} - ${cita.hora}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Doctor: ${cita.medicoNombre} ${cita.medicoApellido}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Especialidad: ${cita.especialidadNombre}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Paciente: ${cita.pacienteNombre} ${cita.pacienteApellido}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Estado: ${cita.estado}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    trailing: puedeCancelar(cita)
                        ? ElevatedButton(
                            onPressed: () => cancelarCita(cita.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text(
                              'Cancelar Cita',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : const Text(
                            'Sin Observaciones',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
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

class Cita {
  final int id;
  final String fecha;
  final String hora;
  final int medicoId;
  final String medicoNombre;
  final String medicoApellido;
  final int pacienteId;
  final String pacienteNombre;
  final String pacienteApellido;
  final int especialidadId;
  final String especialidadNombre;
  final String estado;
  final bool consultaCreada;

  Cita({
    required this.id,
    required this.fecha,
    required this.hora,
    required this.medicoId,
    required this.medicoNombre,
    required this.medicoApellido,
    required this.pacienteId,
    required this.pacienteNombre,
    required this.pacienteApellido,
    required this.especialidadId,
    required this.especialidadNombre,
    required this.estado,
    required this.consultaCreada,
  });

  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      id: json['id'],
      fecha: json['fecha'],
      hora: json['hora'],
      medicoId: json['medicoId'],
      medicoNombre: json['medicoNombre'],
      medicoApellido: json['medicoApellido'],
      pacienteId: json['pacienteId'],
      pacienteNombre: json['pacienteNombre'],
      pacienteApellido: json['pacienteApellido'],
      especialidadId: json['especialidadId'],
      especialidadNombre: json['especialidadNombre'],
      estado: json['estado'],
      consultaCreada: json['consultaCreada'],
    );
  }
}
