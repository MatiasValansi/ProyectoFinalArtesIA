import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Usar dart-define en producción, fallback a dotenv en desarrollo
  static String _getEnvVar(String key, String defaultValue) {
    // Intentar obtener de dart-define primero (producción)
    String? dartDefineValue = String.fromEnvironment(key).isEmpty 
        ? null 
        : String.fromEnvironment(key);
    
    return dartDefineValue ?? dotenv.env[key] ?? defaultValue;
  }

  static String get fileUploadEndpoint =>
      _getEnvVar('IA_FILE_UPLOAD_ENDPOINT', '/api/v2/File/upload');
  static String get fileUploadUrl => iaApiBaseUrl + fileUploadEndpoint;

  static String get iaApiBaseUrl => _getEnvVar('IA_API_BASE_URL', '');
  static String get iaApiKey => _getEnvVar('IA_API_KEY', '');

  static String get nestleCheckAgentEndpoint =>
      _getEnvVar('IA_NESTLE_CHECK_AGENT_ENDPOINT', '');
  static String get volatileKnowledgeEndpoint =>
      _getEnvVar('IA_VOLATILE_KNOWLEDGE_ENDPOINT', '');

  static String get nestleCheckAgentUrl =>
      iaApiBaseUrl + nestleCheckAgentEndpoint;
  static String get volatileKnowledgeUrl =>
      iaApiBaseUrl + volatileKnowledgeEndpoint;

  static Map<String, String> get apiHeaders => {
    'Content-Type': 'application/json',
    'X-API-KEY': iaApiKey,
  };
}
