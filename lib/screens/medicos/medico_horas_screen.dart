import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/widgets/sesion_expirada_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HorasDisponiblesScreen extends StatefulWidget {
  final int medicoId;
  final int especialidadId;

  const HorasDisponiblesScreen({
    super.key,
    required this.medicoId,
    required this.especialidadId,
  });

  @override
  _HorasDisponiblesScreenState createState() => _HorasDisponiblesScreenState();
}

class _HorasDisponiblesScreenState extends State<HorasDisponiblesScreen> {
  Future<List<String>>? _horasDisponibles;
  String? _horaSeleccionada;
  int? _pacienteId;

  DateTime? _fechaSeleccionada;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchPacienteId();
    print('Hora actual del sistema: ${DateTime.now()}');
  }

  Future<List<String>> fetchHorasDisponibles() async {
    if (_fechaSeleccionada == null) {
      throw Exception('Seleccione una fecha para ver las horas disponibles');
    }

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception("Token no encontrado. Redirigiendo al login...");
    }

    // Imprime la fecha y hora actuales del sistema
    final DateTime fechaActual = DateTime.now();
    print('Fecha y hora actual del sistema: $fechaActual');

    print('Fecha seleccionada: $_fechaSeleccionada');
    final response = await http.get(
      Uri.parse(
          'http://143.198.147.110/api/citas/horas-disponibles?fecha=${_fechaSeleccionada!.toIso8601String().split('T').first}&medicoId=${widget.medicoId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      print('Horas disponibles recibidas: $jsonList');

      // Convertir la lista de horas a strings
      List<String> horasDisponibles =
          jsonList.map((hora) => hora.toString()).toList();

      // Filtrar las horas si la fecha seleccionada es igual a la fecha actual
      if (_fechaSeleccionada!.year == fechaActual.year &&
          _fechaSeleccionada!.month == fechaActual.month &&
          _fechaSeleccionada!.day == fechaActual.day) {
        final ahora = TimeOfDay.fromDateTime(fechaActual); // Hora actual
        horasDisponibles = horasDisponibles.where((hora) {
          final horaParts = hora.split(':'); // Dividir la hora (ej. "14:00")
          final horaCita = TimeOfDay(
            hour: int.parse(horaParts[0]),
            minute: int.parse(horaParts[1]),
          );
          return horaCita.hour > ahora.hour ||
              (horaCita.hour == ahora.hour && horaCita.minute > ahora.minute);
        }).toList();
      }

      print('Horas disponibles filtradas: $horasDisponibles');
      return horasDisponibles;
    } else if (response.statusCode == 401) {
      SessionExpiredModal.show(context); // Mostrar modal de sesión expirada
      throw Exception('Sesión expirada.');
    } else {
      print('Error al obtener las horas disponibles: ${response.statusCode}');
      throw Exception('Error al cargar las horas disponibles');
    }
  }

  Future<void> fetchPacienteId() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('accessToken');
    final int? userId = prefs.getInt('userId'); // Obtener userId directamente

    if (token == null || userId == null) {
      throw Exception(
          "Token o userId no encontrados. Redirigiendo al login...");
    }

    final response = await http.get(
      Uri.parse('http://143.198.147.110/api/pacientes'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      for (var paciente in jsonList) {
        if (paciente['usuario']['id'] == userId) {
          // Comparar con el userId obtenido
          setState(() {
            print('Paciente: ${paciente['id']}');
            _pacienteId = paciente['id'];
          });
          break;
        }
      }
    } else if (response.statusCode == 401) {
      SessionExpiredModal.show(context); // Mostrar modal de sesión expirada
      throw Exception('Sesión expirada.');
    } else {
      throw Exception('Error al cargar los pacientes');
    }
  }

  Future<void> agendarCita() async {
    print('PACIENTE ID $_pacienteId');
    if (_pacienteId == null || _horaSeleccionada == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception("Token no encontrado. Redirigiendo al login...");
    }

    final citaData = {
      "fecha": _fechaSeleccionada!.toIso8601String().split('T').first,
      "hora": _horaSeleccionada,
      "medicoId": widget.medicoId,
      "pacienteId": _pacienteId,
      "especialidadId": widget.especialidadId,
    };

    print('Datos de la cita a agendar: $citaData');

    try {
      final response = await http.post(
        Uri.parse('http://143.198.147.110/api/citas/agendar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(citaData),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context); // Navegar hacia atrás después de agendar
      } else if (response.statusCode == 400) {
        SessionExpiredModal.show(context); // Mostrar modal de sesión expirada
        throw Exception('Sesión expirada.');
      } else {
        // Intentar obtener el mensaje de error del cuerpo de la respuesta
        try {
          final responseBody = jsonDecode(response.body);
          final errorMessage =
              'Error ya tienes una cita agendada hoy' ?? 'Error desconocido';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          // Mostrar un mensaje genérico si no se puede decodificar la respuesta
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Error ya tienes una cita agendada hoy.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ocurrió un error: $error')),
      );
    }
  }

  Future<void> seleccionarFecha(BuildContext context) async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              surface: Color(0xFF1E272E),
              onPrimary: Colors.white,
              onSurface: Colors.white70,
            ),
            dialogBackgroundColor: Color(0xFF1E272E),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
        _horaSeleccionada = null;
        _horasDisponibles = fetchHorasDisponibles();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horas disponibles del doctor'),
        backgroundColor: const Color(0xFF1E272E),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => seleccionarFecha(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E272E),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15), // Botón más alto
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10), // Bordes redondeados
                      ),
                    ),
                    icon: const Icon(Icons.date_range,
                        color: Colors.white), // Ícono de selección de fecha
                    label: const Text(
                      'Elige la fecha',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18, // Tamaño del texto más grande
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _fechaSeleccionada != null
                      ? 'Fecha: ${_fechaSeleccionada!.toLocal().toString().split(' ')[0]}'
                      : 'Ninguna fecha seleccionada',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _horasDisponibles,
              builder: (context, snapshot) {
                if (_fechaSeleccionada == null) {
                  return const Center(
                    child: Text(
                      'Por favor, selecciona una fecha para ver las horas disponibles.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No se encontraron horas disponibles.'));
                } else {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 3,
                    ),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final hora = snapshot.data![index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            print('Hora seleccionada $hora');
                            _horaSeleccionada = hora;
                          });
                        },
                        child: Card(
                          color: _horaSeleccionada == hora
                              ? Colors.blueAccent
                              : const Color(0xFF1E272E),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          elevation: 5,
                          child: Center(
                            child: Text(
                              hora,
                              style: TextStyle(
                                color: _horaSeleccionada == hora
                                    ? Colors.white
                                    : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 40.0), // Aumentar espacio horizontal
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  print('presionado');
                  if (_horaSeleccionada != null) {
                    print('llamando');
                    agendarCita(); // Llama a agendarCita si hay una hora seleccionada
                  } else {
                    // Mostrar un mensaje si no se ha seleccionado una hora
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Por favor, selecciona una hora antes de continuar.'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _horaSeleccionada != null
                      ? const Color(0xFF1E272E)
                      : Colors
                          .grey, // Cambia el color si no hay hora seleccionada
                  padding: const EdgeInsets.symmetric(
                      vertical: 20), // Aumentar altura del botón
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15), // Bordes más redondeados
                  ),
                ),
                icon: const Icon(Icons.calendar_today,
                    color: Colors.white), // Ícono de calendario
                label: const Text(
                  'Agendar Cita',
                  style: TextStyle(
                    fontSize: 20, // Tamaño de texto más grande
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
