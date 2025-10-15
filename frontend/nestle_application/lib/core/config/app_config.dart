import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // API Configuration
  static String get iaApiBaseUrl => dotenv.env['IA_API_BASE_URL'] ?? 'https://api.serenitystar.ai';
  static String get iaApiKey => dotenv.env['IA_API_KEY'] ?? '';
  
  // Agent Endpoints
  static String get nestleCheckAgentEndpoint => dotenv.env['IA_NESTLE_CHECK_AGENT_ENDPOINT'] ?? '/api/v2/agent/NestleCheckAsistente/execute';
  static String get nestleJuradoAgentEndpoint => dotenv.env['IA_NESTLE_JURADO_AGENT_ENDPOINT'] ?? '/api/v2/agent/NestleJuradoAsistente/execute';
  
  // Complete URLs
  static String get nestleCheckAgentUrl => iaApiBaseUrl + nestleCheckAgentEndpoint;
  static String get nestleJuradoAgentUrl => iaApiBaseUrl + nestleJuradoAgentEndpoint;
  
  // Headers
  static Map<String, String> get apiHeaders => {
    'Content-Type': 'application/json',
    'X-API-KEY': iaApiKey,
  };
}