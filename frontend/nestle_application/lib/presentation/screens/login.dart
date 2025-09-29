import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nestle_application/domain/movie.dart';

class Login extends StatefulWidget {
  Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _usernameController = TextEditingController();
  String inputText = '';

  List<Movie> movies = [
    Movie(title: 'Inception', director: 'Christopher Nolan', year: 2010, gener: 'Sci-Fi'),
    Movie(title: 'The Godfather', director: 'Francis Ford Coppola', year: 1972, gener: 'Crime'),
    Movie(title: 'Pulp Fiction', director: 'Quentin Tarantino', year: 1994, gener: 'Crime'),
    Movie(title: 'The Dark Knight', director: 'Christopher Nolan', year: 2008, gener: 'Action'),
    Movie(title: 'Forrest Gump', director: 'Robert Zemeckis', year: 1994, gener: 'Drama'),
  ];

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
            Image.network(
              "https://1000marcas.net/wp-content/uploads/2020/01/Nestle-Log%D0%BE-500x281.png",
              height: 80,
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

            // Botón login
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004B93), // Azul Nestlé
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  context.go('/home', extra: _usernameController.text);
                },
                child: const Text(
                  'Ingresar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }
}