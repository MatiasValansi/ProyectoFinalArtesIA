import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Login extends StatefulWidget {
  Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _usernameController = TextEditingController();
  String inputText = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo limpio
      appBar: AppBar(
        backgroundColor: const Color(0xFF004B93), // Azul Nestlé
        title: const Text(
          'Nestlé Login',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Nestlé
            Image.asset(
              "assets/images/NestléLogo.svg.png",
              height: 120,
            ),
            const SizedBox(height: 30),

            const Text(
              'Bienvenido',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Inicia sesión con tus credenciales Nestlé',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Input Username
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline),
                labelText: 'Usuario',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 20),

            // Input Password
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                labelText: 'Contraseña',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 30),

            // Botón login principal
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004B93),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  context.go('/home', extra: _usernameController.text);
                },
                child: const Text(
                  'Ingresar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Texto adicional
            TextButton(
              onPressed: () {},
              child: const Text(
                "¿Olvidaste tu contraseña?",
                style: TextStyle(color: Color(0xFF004B93)),
              ),
            ),

            const SizedBox(height: 30),

            // 🧩 Botón temporal para probar el CRUD de Supabase
            Divider(color: Colors.grey[400]),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF004B93)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Navega a la pantalla de test CRUD
                  context.push('/test-users');
                },
                icon: const Icon(Icons.storage_rounded, color: Color(0xFF004B93)),
                label: const Text(
                  'Probar CRUD de Usuarios (Supabase)',
                  style: TextStyle(color: Color(0xFF004B93)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
