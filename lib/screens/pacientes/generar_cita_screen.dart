import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mapas_api/screens/pacientes/doctores_especialidades_screen.dart';
import 'package:mapas_api/widgets/app_drawer.dart';
import 'package:mapas_api/widgets/sesion_expirada_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Especialidad {
  final int id;
  final String nombre;
  final String descripcion;

  Especialidad(
      {required this.id, required this.nombre, required this.descripcion});

  factory Especialidad.fromJson(Map<String, dynamic> json) {
    return Especialidad(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
    );
  }
}

class EspecialidadesScreen extends StatefulWidget {
  const EspecialidadesScreen({super.key});

  @override
  _EspecialidadesScreenState createState() => _EspecialidadesScreenState();
}

class _EspecialidadesScreenState extends State<EspecialidadesScreen> {
  late Future<List<Especialidad>> _especialidades;

  Future<List<Especialidad>> fetchEspecialidades(BuildContext context) async {
    // Obtén el token almacenado
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception("Token no encontrado. Redirigiendo al login...");
    }

    final response = await http.get(
      Uri.parse('http://143.198.147.110/api/especialidades'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);

      // Agrega el print para verificar cuántas especialidades se reciben
      print("Cantidad de especialidades recibidas: ${jsonList.length}");

      return jsonList.map((json) => Especialidad.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      // Sesión expirada
      SessionExpiredModal.show(
          context); // Llama al modal desde el archivo externo
      throw Exception('Sesión expirada.');
    } else {
      throw Exception(
          'Error al cargar las especialidades: ${response.statusCode}');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _especialidades = fetchEspecialidades(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Especialidades Médicas'),
        backgroundColor: const Color(0xFF1E272E),
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<Especialidad>>(
        future: _especialidades,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SpinKitFadingCircle(
                color: Color(0xFF1E272E),
                size: 50.0,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No se encontraron especialidades.'));
          } else {
            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Escoge una especialidad para generar una cita',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E272E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final especialidad = snapshot.data![index];
                        return EspecialidadCard(
                          especialidad: especialidad,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MedicosPorEspecialidadScreen(
                                  especialidadId: especialidad
                                      .id, // Añadido el parámetro especialidadId
                                  especialidad: especialidad,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class EspecialidadCard extends StatelessWidget {
  final Especialidad especialidad;
  final VoidCallback onTap;

  const EspecialidadCard(
      {super.key, required this.especialidad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // Bordes redondeados
        ),
        elevation: 5, // Sombra de la card
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        child: Container(
          height: 120, // Altura de la card
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E272E), // Fondo oscuro
            borderRadius: BorderRadius.circular(20.0), // Bordes redondeados
            border: Border.all(
                color: Colors.white.withOpacity(0.2)), // Borde tenue blanco
          ),
          child: Row(
            children: [
              // Icono de la especialidad
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2), // Fondo del icono
                  shape: BoxShape.circle, // Icono en forma de círculo
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(width: 20), // Espaciado entre el icono y el texto
              // Texto de la especialidad
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      especialidad.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Texto blanco
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      especialidad.descripcion,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70, // Texto blanco tenue
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
