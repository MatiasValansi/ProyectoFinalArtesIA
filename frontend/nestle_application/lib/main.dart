import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nestle_application/core/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'database/supabase_config.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: "../../.env");
  } catch (e) {
    // En producción (web), es normal que no exista el archivo .env
    // Las variables de entorno se pasan en tiempo de compilación
    print('Archivo .env no encontrado - usando variables de entorno de sistema: $e');
  }

  // Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    throw Exception('No se pudo inicializar Firebase: $e');
  }

  // Inicializar Supabase
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    throw Exception('No se pudo inicializar Supabase: $e');
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Nestlé Application',
      routerConfig: appRouter,
    );
  }
}
