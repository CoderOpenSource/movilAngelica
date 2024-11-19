class Medico {
  final int id;
  final String nombre;
  final String apellido;
  final List<int> especialidadesIds;

  Medico(
      {required this.id,
      required this.nombre,
      required this.apellido,
      required this.especialidadesIds});

  factory Medico.fromJson(Map<String, dynamic> json) {
    return Medico(
      id: json['id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      especialidadesIds: List<int>.from(json['especialidadesIds']),
    );
  }
}

class Horario {
  final String dia;
  final String horaInicio;
  final String horaFin;

  Horario({required this.dia, required this.horaInicio, required this.horaFin});

  factory Horario.fromJson(Map<String, dynamic> json) {
    return Horario(
      dia: json['dia'],
      horaInicio: json['horaInicio'],
      horaFin: json['horaFin'],
    );
  }
}
