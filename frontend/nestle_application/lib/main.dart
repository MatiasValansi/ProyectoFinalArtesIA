import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nestle_application/core/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nestle_application/supabase/supabase_config.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Cargar variables de entorno antes de todo
  try {
    await dotenv.load(fileName: "../../.env");
    debugPrint('✅ Archivo .env cargado correctamente.');
  } catch (e) {
    debugPrint('⚠️ No se pudo cargar el archivo .env: $e');
  }

  // 2️⃣ Inicializar Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('✅ Firebase inicializado.');
  } catch (e) {
    debugPrint('❌ Error al inicializar Firebase: $e');
  }

  // 3️⃣ Inicializar Supabase
  try {
    await SupabaseConfig.initialize();
    debugPrint('✅ Supabase inicializado.');
  } catch (e) {
    debugPrint('❌ Error al inicializar Supabase: $e');
  }

  // 4️⃣ Correr la app
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
