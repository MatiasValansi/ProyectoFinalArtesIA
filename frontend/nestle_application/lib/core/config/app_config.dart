import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Usar dart-define como const en producción, fallback a dotenv en desarrollo
  static String get fileUploadEndpoint =>
      const String.fromEnvironment('IA_FILE_UPLOAD_ENDPOINT', defaultValue: '') != '' 
          ? const String.fromEnvironment('IA_FILE_UPLOAD_ENDPOINT', defaultValue: '/api/v2/File/upload')
          : dotenv.env['IA_FILE_UPLOAD_ENDPOINT'] ?? '/api/v2/File/upload';

  static String get fileUploadUrl => iaApiBaseUrl + fileUploadEndpoint;

  static String get iaApiBaseUrl =>
      const String.fromEnvironment('IA_API_BASE_URL', defaultValue: '') != ''
          ? const String.fromEnvironment('IA_API_BASE_URL', defaultValue: '')
          : dotenv.env['IA_API_BASE_URL'] ?? '';

  static String get iaApiKey =>
      const String.fromEnvironment('IA_API_KEY', defaultValue: '') != ''
          ? const String.fromEnvironment('IA_API_KEY', defaultValue: '')
          : dotenv.env['IA_API_KEY'] ?? '';

  static String get nestleCheckAgentEndpoint =>
      const String.fromEnvironment('IA_NESTLE_CHECK_AGENT_ENDPOINT', defaultValue: '') != ''
          ? const String.fromEnvironment('IA_NESTLE_CHECK_AGENT_ENDPOINT', defaultValue: '')
          : dotenv.env['IA_NESTLE_CHECK_AGENT_ENDPOINT'] ?? '';

  static String get volatileKnowledgeEndpoint =>
      const String.fromEnvironment('IA_VOLATILE_KNOWLEDGE_ENDPOINT', defaultValue: '') != ''
          ? const String.fromEnvironment('IA_VOLATILE_KNOWLEDGE_ENDPOINT', defaultValue: '')
          : dotenv.env['IA_VOLATILE_KNOWLEDGE_ENDPOINT'] ?? '';

  static String get nestleCheckAgentUrl =>
      iaApiBaseUrl + nestleCheckAgentEndpoint;
  static String get volatileKnowledgeUrl =>
      iaApiBaseUrl + volatileKnowledgeEndpoint;

  static Map<String, String> get apiHeaders => {
    'Content-Type': 'application/json',
    'X-API-KEY': iaApiKey,
  };
}
