import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/screens/medicos/medico_horas_screen.dart';
import 'package:mapas_api/screens/medicos/modelos.dart';
import 'package:mapas_api/screens/pacientes/generar_cita_screen.dart';
import 'package:mapas_api/widgets/sesion_expirada_widget.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MedicosPorEspecialidadScreen extends StatefulWidget {
  final int especialidadId;
  final Especialidad especialidad;

  const MedicosPorEspecialidadScreen({
    super.key,
    required this.especialidadId,
    required this.especialidad,
  });

  @override
  _MedicosPorEspecialidadScreenState createState() =>
      _MedicosPorEspecialidadScreenState();
}

class _MedicosPorEspecialidadScreenState
    extends State<MedicosPorEspecialidadScreen> {
  late Future<List<Medico>> _medicos;

  Future<List<Medico>> fetchMedicosPorEspecialidad(
      BuildContext context, int especialidadId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception("Token no encontrado. Redirigiendo al login...");
    }

    final response = await http.get(
      Uri.parse('http://143.198.147.110/api/medicos'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList
          .map((json) => Medico.fromJson(json))
          .where((medico) => medico.especialidadesIds.contains(especialidadId))
          .toList();
    } else if (response.statusCode == 401) {
      SessionExpiredModal.show(context);
      throw Exception('Sesión expirada.');
    } else {
      throw Exception('Error al cargar los médicos');
    }
  }

  Future<List<Horario>> fetchHorariosPorMedico(
      BuildContext context, int medicoId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception("Token no encontrado. Redirigiendo al login...");
    }

    final response = await http.get(
      Uri.parse('http://143.198.147.110/api/horarios/medico/$medicoId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Horario.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      SessionExpiredModal.show(context);
      throw Exception('Sesión expirada.');
    } else {
      throw Exception('Error al cargar los horarios');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _medicos = fetchMedicosPorEspecialidad(context, widget.especialidadId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Médicos de ${widget.especialidad.nombre}'),
        backgroundColor: const Color(0xFF1E272E),
      ),
      body: FutureBuilder<List<Medico>>(
        future: _medicos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No hay médicos disponibles para esta especialidad.',
                style: TextStyle(color: Colors.white),
              ),
            );
          } else {
            final medicos = snapshot.data!;
            return ListView.builder(
              itemCount: medicos.length,
              itemBuilder: (context, index) {
                final medico = medicos[index];
                return FutureBuilder<List<Horario>>(
                  future: fetchHorariosPorMedico(context, medico.id),
                  builder: (context, horarioSnapshot) {
                    if (horarioSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (horarioSnapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Error al cargar horarios',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    } else {
                      final horarios = horarioSnapshot.data ?? [];
                      return MedicoCard(
                        medico: medico,
                        horarios: horarios,
                        especialidadId: widget.especialidadId,
                      );
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

class MedicoCard extends StatelessWidget {
  final Medico medico;
  final List<Horario> horarios;
  final int especialidadId;

  const MedicoCard({
    super.key,
    required this.medico,
    required this.horarios,
    required this.especialidadId,
  });

  void _navegarAHorasDisponibles(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HorasDisponiblesScreen(
          medicoId: medico.id,
          especialidadId: especialidadId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navegarAHorasDisponibles(context),
      child: Card(
        color: const Color(0xFF1E272E), // Fondo oscuro
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, size: 40, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${medico.nombre} ${medico.apellido}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              horarios.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: horarios.map((horario) {
                        return Text(
                          '${horario.dia}: ${horario.horaInicio} - ${horario.horaFin}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        );
                      }).toList(),
                    )
                  : const Text(
                      'Sin horarios disponibles',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
