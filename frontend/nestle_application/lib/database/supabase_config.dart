import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//Configuración de la base de datos Supabase
class SupabaseConfig {
  static Future<void> initialize() async {
    // Obtener variables usando const String.fromEnvironment
    String supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: '') != ''
        ? const String.fromEnvironment('SUPABASE_URL', defaultValue: '')
        : dotenv.env['SUPABASE_URL'] ?? '';
    
    String supabaseKey = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '') != ''
        ? const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '')
        : dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      return;
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }


  static SupabaseClient get client => Supabase.instance.client;
}
