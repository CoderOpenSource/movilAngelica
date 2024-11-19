import 'package:flutter/material.dart';
import 'package:mapas_api/widgets/app_drawer.dart'; // Asegúrate de importar AppDrawer aquí

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial Clínico Electrónico"),
        backgroundColor: const Color(0xFF1E272E), // Lila oscuro para el AppBar
        centerTitle: false,
      ),
      drawer: const AppDrawer(), // Drawer que llamará a AppDrawer
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introducción general
            Text(
              "Bienvenido al Sistema de Historial Clínico Electrónico",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E272E), // Lila oscuro
              ),
            ),
            SizedBox(height: 16), // Espaciado entre elementos
            Text(
              "Nuestro sistema de historial clínico electrónico permite a los profesionales de la salud gestionar y acceder de forma segura a la información médica de sus pacientes.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 24),

            // Beneficios del sistema
            Text(
              "Beneficios del Sistema",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "• Acceso rápido y seguro a la información del paciente.\n• Mejora en la coordinación de atención entre profesionales de la salud.\n• Reducción de errores al tener información precisa y actualizada.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 24),

            // Características principales
            Text(
              "Características Principales",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E272E),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "• Registro completo del historial médico del paciente.\n• Integración con laboratorios para acceder a resultados de pruebas.\n• Programación de citas y recordatorios.\n• Generación de reportes médicos personalizados.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 24),

            // Seguridad y privacidad
            Text(
              "Seguridad y Privacidad",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Todos los datos están protegidos y cumplen con las normativas de privacidad, garantizando la confidencialidad de la información del paciente.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 24),

            // Mensaje motivacional
            Text(
              "Facilitando la atención médica de manera eficiente y confiable.",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Nuestro sistema de historial clínico electrónico está diseñado para que el personal médico pueda centrarse en lo que realmente importa: el bienestar del paciente.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
