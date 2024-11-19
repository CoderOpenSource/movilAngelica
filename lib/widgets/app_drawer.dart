import 'package:flutter/material.dart';
import 'package:mapas_api/screens/analisis/mis_analisis.dart';
import 'package:mapas_api/screens/client/citas/mis_citas_screen.dart';
import 'package:mapas_api/screens/consultas/mis_consultas.dart';
import 'package:mapas_api/screens/home_screen.dart';
import 'package:mapas_api/screens/pacientes/generar_cita_screen.dart';
import 'package:mapas_api/screens/pacientes/historial_screen.dart';
import 'package:mapas_api/screens/user/login_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? _nombreCompleto;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    _nombreCompleto = prefs.getString('nombreCompleto');
    _role = prefs.getString('rol');

    if (_nombreCompleto != null || _role == null) {
      // Si no hay datos en SharedPreferences, realizar la solicitud
      await _fetchAndSaveUserDetails();
    }

    setState(() {});
  }

  Future<void> _fetchAndSaveUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('accessToken');
    final int? userId = prefs.getInt('userId');

    if (token == null || userId == null) {
      // Si no hay token o userId, redirigir al login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
      return;
    }

    final String url = 'http://143.198.147.110/usuarios/$userId';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _nombreCompleto = "${data['nombre']} ${data['apellido']}";
        _role = data['rol']['nombre'];

        // Guardar los datos en SharedPreferences
        await prefs.setString('nombreCompleto', _nombreCompleto!);
        await prefs.setString('rol', _role!);

        setState(() {});
      } else {
        print('Error al obtener los datos del usuario: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de red al obtener los datos del usuario: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildDrawer();
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E272E), // Lila oscuro
              Colors.white, // Blanco
            ],
          ),
        ),
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1E272E), // Lila oscuro para el DrawerHeader
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: const NetworkImage(
                        'https://res.cloudinary.com/dhok8ieuv/image/upload/v1726490883/pngwing.com_4_aq4v9b.png'), // Imagen predeterminada
                    child: _nombreCompleto == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _nombreCompleto ?? 'Cargando...',
                    style: const TextStyle(color: Colors.white, fontSize: 20.0),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _role ?? 'Cargando...',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 16.0),
                  ),
                ],
              ),
            ),
            // Opciones según el rol
            if (_role == 'PACIENTE') ...[
              _buildDrawerItem(Icons.home, 'Home', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              }),
              _buildDrawerItem(Icons.supervised_user_circle, 'Generar Cita',
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EspecialidadesScreen()),
                );
              }),
              _buildDrawerItem(Icons.calendar_month, 'Mis Citas', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MisCitasScreen()),
                );
              }),
              _buildDrawerItem(Icons.date_range, 'Mis Consultas', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MisConsultasScreen()),
                );
              }),
              _buildDrawerItem(Icons.file_present, 'Mis Analisis', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MisAnalisisScreen()),
                );
              }),
              _buildDrawerItem(Icons.document_scanner, 'Ver mi Historial', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HistorialClinicoScreen()),
                );
              }),
              _buildDrawerItem(Icons.settings, 'Configuración', () {}),
              _buildDrawerItem(Icons.help, 'Ayuda', () {
                // Implementar navegación a la pantalla de ayuda
              }),
            ] else if (_role == 'MEDICO') ...[
              _buildDrawerItem(Icons.people, 'Gestionar Pacientes Atendidos',
                  () {
                // Navegar a la gestión de pacientes atendidos
              }),
              _buildDrawerItem(Icons.schedule, 'Ver Horarios', () {
                // Navegar a la pantalla de horarios
              }),
              _buildDrawerItem(Icons.calendar_today, 'Gestionar Citas', () {
                // Navegar a la gestión de citas
              }),
              _buildDrawerItem(Icons.medical_services, 'Gestionar Consultas',
                  () {
                // Navegar a la gestión de consultas
              }),
            ],
            // Botón para cerrar sesión
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () => _showLogoutConfirmation(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E272E), // Lila oscuro
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Cerrar sesión",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E272E)),
      title: Text(title, style: const TextStyle(color: Color(0xFF1E272E))),
      onTap: onTap,
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar'),
          content: const Text('¿Quieres cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _logout(context);
              },
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );
  }
}

void _logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();

  // Remueve las preferencias guardadas
  prefs.remove('accessToken'); // Remueve el token
  prefs.remove('username'); // Remueve el nombre de usuario
  prefs.remove('userId'); // Remueve el userId
  prefs.remove('fcmToken'); // Remueve el token FCM
  prefs.remove('rol');
  prefs.remove('nombreCompleto');
  print("Preferencias eliminadas: token, username, userId, fcmToken.");

  // Navegar a la página de login y eliminar todas las demás pantallas de la pila de navegación
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (BuildContext context) =>
          const LoginView(), // Suponiendo que la vista de login se llama LoginView
    ),
    (Route<dynamic> route) => false, // Esto elimina todas las pantallas previas
  );
}
