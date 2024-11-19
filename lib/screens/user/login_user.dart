import 'package:mapas_api/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  String? _error;

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    const String url =
        'http://143.198.147.110/authenticate/'; // URL para el emulador de Android

    try {
      // Crear el cuerpo de la solicitud
      final body = jsonEncode({
        'username': emailController.text,
        'password': passwordController.text,
      });

      // Realizar la solicitud POST al servidor
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        // Parsear la respuesta del servidor
        final data = jsonDecode(response.body);
        final token = data['token'];
        final role = data['rol']; // Verificar el rol
        final userId = data['id'];

        if (role != 'PACIENTE' && role != 'MEDICO') {
          // Mostrar mensaje de error si no es PACIENTE
          setState(() {
            _error = 'Acceso denegado: Solo los PACIENTES pueden ingresar.';
          });
          return;
        }

        // Guardar el token y otros datos en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', token);
        await prefs.setString('username', emailController.text);
        await prefs.setString('password', passwordController.text);
        await prefs.setInt('userId', userId);
        await prefs.setString('rol', role); // Almacenar el rol
        print("USER ID----->$userId");
        // Navegar a la pantalla principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyApp()),
        );
      } else {
        // Manejar errores de inicio de sesión
        setState(() {
          _error = 'Inicio de sesión fallido: ${response.body}';
        });
      }
    } catch (error) {
      // Manejar excepciones
      setState(() {
        _error = 'Error: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithBiometrics() async {
    final LocalAuthentication auth = LocalAuthentication();

    try {
      // Verificar si el dispositivo admite autenticación biométrica
      final bool canAuthenticate =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        _showNoBiometricsModal();
        return;
      }

      // Intentar autenticación biométrica
      final bool authenticated = await auth.authenticate(
        localizedReason: 'Por favor, autentícate para acceder.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        // Si la autenticación es exitosa, intenta iniciar sesión
        final prefs = await SharedPreferences.getInstance();
        final String? email = prefs.getString('username');
        final String? password = prefs.getString('password');

        if (email == null || password == null) {
          _showNoDataModal();
          return;
        }

        setState(() {
          _isLoading = true;
        });

        const String url = 'http://143.198.147.110/authenticate/';

        final body = jsonEncode({
          'username': email,
          'password': password,
        });

        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final token = data['token'];
          final userId = data['id'];
          final role = data['rol'];

          await prefs.setString('rol', role); // Almacenar el rol

          await prefs.setString('accessToken', token);
          await prefs.setInt('userId', userId);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyApp()),
          );
        } else {
          setState(() {
            _error = 'Inicio de sesión fallido: ${response.body}';
          });
        }
      } else {
        setState(() {
          _error = 'Autenticación biométrica fallida.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error en la autenticación biométrica: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// Mostrar un modal si no hay datos almacenados
  void _showNoDataModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E272E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Datos no encontrados',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'No se encontraron datos de inicio de sesión almacenados. Por favor, ingresa tu correo y contraseña manualmente.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Aceptar',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

// Mostrar un modal si no hay biométricos disponibles
  void _showNoBiometricsModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E272E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Autenticación no disponible',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Tu dispositivo no admite autenticación biométrica. Por favor, usa tu correo y contraseña.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Aceptar',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _loadingOverlay() {
    return _isLoading
        ? Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Espere por favor...",
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 10, 11, 11),
                  Color.fromARGB(0, 91, 168, 213),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(
                            16.0), // Espaciado alrededor del título
                        child: Text(
                          'HISTORIA CLÍNICA ELECTRÓNICA SSVS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // Ajustar color del texto
                          ),
                        ),
                      ),
                      Container(
                        height: 220,
                        width: 400,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/pngwing.png'),
                            fit: BoxFit.fitHeight,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Card(
                        color: Colors.black.withOpacity(0.7),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Iniciar sesión:",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: emailController,
                                style:
                                    const TextStyle(color: Color(0xFF1E272E)),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.email_sharp,
                                      color: Color(0xFF1E272E)),
                                  labelText: 'Correo electrónico',
                                  labelStyle:
                                      const TextStyle(color: Color(0xFF1E272E)),
                                  hintText: 'Correo electrónico',
                                  hintStyle:
                                      const TextStyle(color: Color(0xFF1E272E)),
                                  border: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                        color: Color(0xFF1E272E)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                        color: Color(0xFF1E272E)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  focusColor: Colors.transparent,
                                ),
                              ),
                              const SizedBox(height: 15),
                              TextField(
                                controller: passwordController,
                                obscureText: _obscureText,
                                style:
                                    const TextStyle(color: Color(0xFF1E272E)),
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  labelStyle:
                                      const TextStyle(color: Color(0xFF1E272E)),
                                  hintText: 'Contraseña',
                                  hintStyle:
                                      const TextStyle(color: Color(0xFF1E272E)),
                                  border: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                        color: Color(0xFF1E272E)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                        color: Color(0xFF1E272E)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureText
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: const Color(0xFF1E272E),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.password,
                                    color: Color(0xFF1E272E),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  focusColor: Colors.transparent,
                                ),
                              ),
                              const SizedBox(height: 15),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSignIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E272E),
                                    padding: const EdgeInsets.all(12),
                                  ),
                                  child: const Text(
                                    "Iniciar sesión",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isLoading ? null : _loginWithBiometrics,
                                  icon: const Icon(Icons.fingerprint),
                                  label: const Text('Acceso biométrico'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey,
                                    padding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    "¿Has olvidado la contraseña?",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => MyApp()),
                                    );
                                  },
                                  child: const Text(
                                    "¿No tienes una cuenta? Regístrate",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ),
                              if (_error != null)
                                Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading) _loadingOverlay(),
        ],
      ),
    );
  }
}
