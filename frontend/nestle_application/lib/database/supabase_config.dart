import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//Configuración de la base de datos Supabase
class SupabaseConfig {
  static Future<void> initialize() async {
    // Obtener variables de dart-define o dotenv
    String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    String supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    
    // Si están vacías, intentar dotenv
    if (supabaseUrl.isEmpty) {
      supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    }
    if (supabaseKey.isEmpty) {
      supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    }

    print('🔍 Supabase URL: ${supabaseUrl.isNotEmpty ? "✅ Configurada" : "❌ Vacía"}');
    print('🔍 Supabase Key: ${supabaseKey.isNotEmpty ? "✅ Configurada" : "❌ Vacía"}');

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      print('⚠️ Variables de Supabase no configuradas, continuando sin Supabase');
      return;
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }


  static SupabaseClient get client => Supabase.instance.client;
}
