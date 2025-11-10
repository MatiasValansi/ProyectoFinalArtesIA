import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nestle_application/core/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'database/supabase_config.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart'; // 👈 Importante para kIsWeb

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solo cargar .env en desarrollo local (no web)
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: "../../.env");
      print('✅ Archivo .env cargado exitosamente (modo desarrollo)');
    } catch (e) {
      print('⚠️ No se pudo cargar .env, continuando con dart-define');
    }
  } else {
    print('🌐 Modo web: usando variables --dart-define');
  }

  // Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado correctamente');
  } catch (e) {
    print('❌ Error inicializando Firebase: $e');
  }

  // Inicializar Supabase
  try {
    await SupabaseConfig.initialize();
    print('✅ Supabase inicializado correctamente');
  } catch (e) {
    print('❌ Error inicializando Supabase: $e');
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
