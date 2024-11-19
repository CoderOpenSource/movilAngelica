import 'package:flutter/material.dart';
import 'package:mapas_api/screens/user/login_user.dart';

class SessionExpiredModal {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Evita cerrar el modal tocando fuera
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // Bordes redondeados
          ),
          backgroundColor: const Color(0xFF1E272E), // Fondo del modal
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Tamaño ajustado al contenido
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 60,
                  color: Colors.redAccent, // Icono de advertencia
                ),
                const SizedBox(height: 15),
                const Text(
                  'Sesión Expirada',
                  style: TextStyle(
                    color: Colors.white, // Texto en blanco
                    fontSize: 22, // Tamaño del texto
                    fontWeight: FontWeight.bold, // Texto en negrita
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
                  style: TextStyle(
                    color: Colors.white70, // Texto con opacidad
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Navegar a la página de login y eliminar todas las demás pantallas de la pila de navegación
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (BuildContext context) => const LoginView(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent, // Color del botón
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 20.0,
                    ),
                  ),
                  child: const Text(
                    'Aceptar',
                    style: TextStyle(
                      color: Colors.white, // Texto blanco
                      fontSize: 16, // Tamaño del texto
                      fontWeight: FontWeight.bold, // Texto en negrita
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
