import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get fileUploadEndpoint =>
      dotenv.env['IA_FILE_UPLOAD_ENDPOINT'] ?? '/api/v2/File/upload';
  static String get fileUploadUrl => iaApiBaseUrl + fileUploadEndpoint;

  static String get iaApiBaseUrl => dotenv.env['IA_API_BASE_URL'] ?? '';
  static String get iaApiKey => dotenv.env['IA_API_KEY'] ?? '';

  static String get nestleCheckAgentEndpoint =>
      dotenv.env['IA_NESTLE_CHECK_AGENT_ENDPOINT'] ?? '';
  static String get volatileKnowledgeEndpoint =>
      dotenv.env['IA_VOLATILE_KNOWLEDGE_ENDPOINT'] ?? '';

  static String get nestleCheckAgentUrl =>
      iaApiBaseUrl + nestleCheckAgentEndpoint;
  static String get volatileKnowledgeUrl =>
      iaApiBaseUrl + volatileKnowledgeEndpoint;

  static Map<String, String> get apiHeaders => {
    'Content-Type': 'application/json',
    'X-API-KEY': iaApiKey,
  };
}
