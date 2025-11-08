import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//Configuración de la base de datos Supabase
class SupabaseConfig {
  static Future<void> initialize() async {
    // Obtener variables de dart-define o dotenv
    String supabaseUrl = String.fromEnvironment('SUPABASE_URL').isEmpty
        ? dotenv.env['SUPABASE_URL'] ?? ''
        : String.fromEnvironment('SUPABASE_URL');
    
    String supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY').isEmpty
        ? dotenv.env['SUPABASE_ANON_KEY'] ?? ''
        : String.fromEnvironment('SUPABASE_ANON_KEY');

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      throw Exception('Variables de Supabase no configuradas');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }


  static SupabaseClient get client => Supabase.instance.client;
}
