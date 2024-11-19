import 'dart:convert';

import 'package:firebase_core/firebase_core.dart'; // Firebase Core
import 'package:firebase_messaging/firebase_messaging.dart'; // Firebase Messaging
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapas_api/blocs/blocs.dart';
import 'package:mapas_api/blocs/pagar/pagar_bloc.dart';
import 'package:mapas_api/models/theme_provider.dart';
import 'package:mapas_api/screens/home_screen.dart';
import 'package:mapas_api/screens/user/login_user.dart';
import 'package:mapas_api/services/traffic_service.dart';
import 'package:mapas_api/themes/dark_theme.dart';
import 'package:mapas_api/themes/light_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';

/// Maneja notificaciones en segundo plano
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Asegúrate de inicializar Firebase si es necesario
  await Firebase.initializeApp();

  // Imprimir información de la notificación
  print("=== Notificación recibida en segundo plano ===");
  print("Título: ${message.notification?.title}");
  print("Cuerpo: ${message.notification?.body}");
  print("Datos: ${message.data}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Inicializar widgets necesarios

  try {
    await Firebase.initializeApp();
    print('Firebase inicializado correctamente.');
  } catch (e) {
    print('Error inicializando Firebase: $e');
  }

  // Configurar Firebase Messaging para manejar notificaciones en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Configurar Stripe
  Stripe.publishableKey =
      'pk_test_51OM6g0A7qrAo0IhR3dbWDmmwmpyZ6fu5WcwDQ9kSNglvbcqlPKy4xXSlwltVkGOkQgWh12T7bFJgjCQq3B7cGaFV007JonVDPp';
  await Stripe.instance.applySettings();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => GpsBloc()),
        BlocProvider(create: (context) => LocationBloc()),
        BlocProvider(
            create: (context) =>
                MapBloc(locationBloc: BlocProvider.of<LocationBloc>(context))),
        BlocProvider(
            create: (context) => SearchBloc(trafficService: TrafficService())),
        BlocProvider(create: (_) => PagarBloc())
      ],
      child: ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          // <-- Envuelve aquí con MaterialApp
          debugShowCheckedModeBanner: false,
          theme: lightUberTheme, // Asegúrate de tener tus temas configurados
          darkTheme: darkUberTheme,
          themeMode: ThemeMode.system,
          home: const MyApp(),
        ),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<SharedPreferences> prefsFuture;
  bool? _isAuthenticated;

  @override
  void initState() {
    super.initState();
    prefsFuture = SharedPreferences.getInstance();
    _checkAuthentication();

    // Configuración de Firebase Messaging
    _configureFirebaseMessaging();
  }

  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    setState(() {
      _isAuthenticated = token != null && token.isNotEmpty;
    });
  }

  /// Configuración de Firebase Messaging
  void _configureFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Solicitar permisos de notificaciones
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("Permisos de notificaciones otorgados.");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print("Permisos provisionales otorgados.");
    } else {
      print("Permisos de notificaciones denegados.");
      return; // Salir si no se otorgaron permisos
    }

    // Obtener el token FCM inicial y compararlo con el guardado
    messaging.getToken().then((token) async {
      if (token == null) {
        print(
            "No se pudo obtener el token FCM. Verifica la configuración de Firebase.");
        return; // Salir si no hay token
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Guardar el token localmente (por si lo necesitas en el futuro)
      await prefs.setString('fcmToken', token);
      print("Token FCM inicial: $token");

      // Enviar siempre el token al backend
      _sendTokenToBackend(token);
    }).catchError((error) {
      print("Error al obtener el token FCM: $error");
    });

    // Escuchar cambios en el token
    messaging.onTokenRefresh.listen((newToken) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      print("Token FCM actualizado: $newToken");
      await prefs.setString('fcmToken', newToken);
      _sendTokenToBackend(newToken); // Enviar el token actualizado al backend
    });

    // Manejar notificaciones recibidas en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Notificación recibida en primer plano:");
      print("Título: ${message.notification?.title}");
      print("Cuerpo: ${message.notification?.body}");

      // Mostrar el modal al recibir la notificación
      _showNotificationModal(
        context,
        message.notification?.title ?? 'Sin título',
        message.notification?.body ?? 'Sin contenido',
      );
    });

    // Manejar notificaciones cuando se tocan y abren la app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notificación abierta:");
      print("Datos: ${message.data}");
    });
  }

  void _showNotificationModal(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E272E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Row(
            children: const [
              Icon(Icons.notifications, color: Colors.blueAccent),
              SizedBox(width: 10),
              Text(
                'Notificación recibida',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Aceptar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Método para enviar el token al backend
  void _sendTokenToBackend(String token) async {
    // Obtener la instancia de SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Obtener el userId y accessToken almacenados
    int? userId = prefs.getInt('userId');
    String? accessToken = prefs.getString('accessToken');

    if (userId == null || accessToken == null) {
      print(
          "No se encontró un userId o accessToken en SharedPreferences. No se puede enviar el token.");
      return; // Salir si no hay userId o accessToken
    }

    // Configurar los headers para incluir el accessToken
    final headers = {
      "Authorization": "Bearer $accessToken",
    };

    // Construir la URL con el parámetro `fcmToken`
    final url = Uri.parse(
        "http://143.198.147.110/usuarios/$userId/fcm-token?fcmToken=$token");

    // Realizar la solicitud PATCH
    final response = await http.patch(
      url,
      headers: headers,
    );

    // Verificar la respuesta
    if (response.statusCode == 200) {
      print("Token FCM enviado al backend correctamente.");
    } else {
      print("Error al enviar el token FCM: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: themeProvider.isDarkMode ? darkUberTheme : lightUberTheme,
          home: _isAuthenticated != true
              ? const LoginView() // Si no está autenticado, muestra el LoginView
              : const HomeScreen(), // Si está autenticado, carga directamente HomeScreen
        );
      },
    );
  }
}
