import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import '../config/app_config.dart';
import 'package:http/http.dart' as http;

class SerenityApiService {
  /// Inicializar una nueva conversación
  Future<String> initializeChat() async {
    int maxRetries = 3;
    int currentRetry = 0;

    while (currentRetry < maxRetries) {
      try {
        final uri = Uri.parse(
          AppConfig.iaApiBaseUrl + AppConfig.nestleCheckAgentEndpoint,
        );

        final headers = {
          'Content-Type': 'application/json',
          'X-API-KEY': AppConfig.iaApiKey,
        };

        final body = json.encode([
          {"key": "message", "value": "Inicializar chat"},
        ]);

        final response = await http
            .post(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          return jsonData['instanceId'] ?? '';
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        currentRetry++;
        if (currentRetry >= maxRetries) {
          throw Exception(
            'Error al inicializar chat después de $maxRetries intentos: $e',
          );
        }

        await Future.delayed(Duration(seconds: currentRetry * 2));
      }
    }

    throw Exception('Error inesperado al inicializar chat');
  }

  /// Subir imagen
  Future<String> uploadImage(html.File file) async {
    int maxRetries = 3;
    int currentRetry = 0;

    while (currentRetry < maxRetries) {
      try {
        final formData = html.FormData();
        formData.appendBlob('File', file, file.name);

        final request = html.HttpRequest();
        request.open('POST', AppConfig.volatileKnowledgeUrl);
        request.setRequestHeader('X-API-KEY', AppConfig.iaApiKey);

        final completer = Completer<String>();
        request.onLoadEnd.listen((e) {
          if (request.status == 200 && request.responseText != null) {
            try {
              final responseData = json.decode(request.responseText!);
              final volatileKnowledgeId = responseData['id'] ?? '';

              if (volatileKnowledgeId.isEmpty) {
                completer.completeError('Error al subir imagen');
                return;
              }
              completer.complete(volatileKnowledgeId);
            } catch (e) {
              completer.completeError('Error parsing response: $e');
            }
          } else {
            completer.completeError(
              'HTTP ${request.status}: ${request.responseText}',
            );
          }
        });

        request.onError.listen((e) {
          completer.completeError('Network error: $e');
        });

        request.onTimeout.listen((e) {
          completer.completeError('Request timeout');
        });

        request.timeout = 60000;
        request.send(formData);

        return await completer.future;
      } catch (e) {
        currentRetry++;
        if (currentRetry >= maxRetries) {
          throw Exception(
            'Error al subir imagen después de $maxRetries intentos: $e',
          );
        }

        await Future.delayed(Duration(seconds: currentRetry * 2));
      }
    }

    throw Exception('Error inesperado al subir imagen');
  }

  /// Verificar el estado del volatile knowledge
  Future<Map<String, dynamic>> getVolatileKnowledgeStatus(String volatileKnowledgeId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.iaApiBaseUrl}/api/v2/VolatileKnowledge/$volatileKnowledgeId'),
      headers: {
        'X-API-KEY': AppConfig.iaApiKey,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al verificar estado del volatile knowledge: ${response.statusCode}');
    }
  }

  /// Esperar hasta que el volatile knowledge esté listo
  Future<void> waitForVolatileKnowledgeReady(String volatileKnowledgeId) async {
    const delayBetweenAttempts = Duration(seconds: 10);

    while (true) {
      try {
        final status = await getVolatileKnowledgeStatus(volatileKnowledgeId);
        
        // Verificar si el estado es "success"
        if (status['status'] == 'success') {
          return; // El volatile knowledge está listo
        }
        
        // Si hay un error en el procesamiento, lanzar excepción
        if (status['status'] == 'failed' || status['status'] == 'error') {
          throw Exception('Error al procesar la imagen: ${status['status']}');
        }
        
        // Si está en progreso, esperar y continuar
        await Future.delayed(delayBetweenAttempts);
      } catch (e) {
        // Si es un error de estado (failed/error), relanzar
        if (e.toString().contains('Error al procesar la imagen')) {
          rethrow;
        }
        // Para otros errores, esperar y continuar
        await Future.delayed(delayBetweenAttempts);
      }
    }
  }

  /// Ejecutar análisis
  Future<AnalysisResponse> executeAnalysis(String chatId, String fileId) async {
    int maxRetries = 3;
    int currentRetry = 0;

    while (currentRetry < maxRetries) {
      try {
        final uri = Uri.parse(
          AppConfig.iaApiBaseUrl + AppConfig.nestleCheckAgentEndpoint,
        );

        final headers = {
          'Content-Type': 'application/json',
          'X-API-KEY': AppConfig.iaApiKey,
        };

        final body = json.encode([
          {"key": "chatId", "value": chatId},
          {
            "key": "message",
            "value": "Analiza esta imagen según los estándares de Nestlé",
          },
          {
            "key": "volatileKnowledgeIds",
            "value": [fileId],
          },
        ]);

        final response = await http
            .post(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 600));

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          return AnalysisResponse.fromJson(jsonData);
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        currentRetry++;
        if (currentRetry >= maxRetries) {
          throw Exception(
            'Error al ejecutar análisis después de $maxRetries intentos: $e',
          );
        }

        // Esperar antes del siguiente intento
        await Future.delayed(Duration(seconds: currentRetry * 3));
      }
    }

    throw Exception('Error inesperado al ejecutar análisis');
  }
}

/// Modelo para la respuesta del upload de archivo
class FileUploadResponse {
  final String id;
  final String extension;
  final String name;
  final String? expirationDate;

  FileUploadResponse({
    required this.id,
    required this.extension,
    required this.name,
    this.expirationDate,
  });

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    return FileUploadResponse(
      id: json['id'] ?? '',
      extension: json['extension'] ?? '',
      name: json['name'] ?? '',
      expirationDate: json['expirationDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'extension': extension,
      'name': name,
      'expirationDate': expirationDate,
    };
  }
}

/// Modelo para la respuesta del análisis
class AnalysisResponse {
  final String content;
  final dynamic jsonContent;
  final dynamic metaAnalysis;
  final List<dynamic> violations;
  final int timeToFirstToken;
  final String instanceId;
  final Map<String, dynamic>? actionResults;

  AnalysisResponse({
    required this.content,
    this.jsonContent,
    this.metaAnalysis,
    required this.violations,
    required this.timeToFirstToken,
    required this.instanceId,
    this.actionResults,
  });

  factory AnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisResponse(
      content: json['content'] ?? '',
      jsonContent: json['jsonContent'],
      metaAnalysis: json['metaAnalysis'],
      violations: List<dynamic>.from(json['violations'] ?? []),
      timeToFirstToken: json['timeToFirstToken'] ?? 0,
      instanceId: json['instanceId'] ?? '',
      actionResults: json['actionResults'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'jsonContent': jsonContent,
      'metaAnalysis': metaAnalysis,
      'violations': violations,
      'timeToFirstToken': timeToFirstToken,
      'instanceId': instanceId,
      'actionResults': actionResults,
    };
  }
}
