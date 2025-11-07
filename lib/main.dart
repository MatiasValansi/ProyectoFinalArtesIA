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
    throw Exception('No se pudo cargar el archivo .env: $e');
  }
  const apiBaseUrl = String.fromEnvironment('IA_API_BASE_URL', defaultValue: '');
  const apiKey = String.fromEnvironment('IA_API_KEY', defaultValue: '');
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  final effectiveSupabaseUrl = supabaseUrl.isNotEmpty
      ? supabaseUrl
      : dotenv.env['SUPABASE_URL'] ?? '';
  final effectiveSupabaseKey = supabaseKey.isNotEmpty
      ? supabaseKey
      : dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  print('🚀 IA_API_BASE_URL: $apiBaseUrl');
  print('🚀 SUPABASE_URL: $effectiveSupabaseUrl');
  print('🚀 SUPABASE_KEY (primeros 8): ${effectiveSupabaseKey.substring(0, 8)}');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    throw Exception('No se pudo inicializar Firebase: $e');
  }
  try {
    await SupabaseConfig.initialize(
      url: effectiveSupabaseUrl,
      anonKey: effectiveSupabaseKey,
    );
    print('✅ Supabase inicializado correctamente');
  } catch (e, st) {
    print('❌ Error al inicializar Supabase: $e');
    print(st);
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