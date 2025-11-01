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
  final uri = Uri.parse(AppConfig.iaApiBaseUrl + AppConfig.nestleCheckAgentEndpoint);
        
        final headers = {
          'Content-Type': 'application/json',
          'X-API-KEY': AppConfig.iaApiKey,
        };
        
        final body = json.encode([
          {
            "key": "message",
            "value": "Inicializar chat"
          }
        ]);
        
        final response = await http.post(
          uri, 
          headers: headers, 
          body: body,
        ).timeout(const Duration(seconds: 30));
        
        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          return jsonData['instanceId'] ?? '';
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        currentRetry++;
        if (currentRetry >= maxRetries) {
          throw Exception('Error al inicializar chat después de $maxRetries intentos: $e');
        }
        
        await Future.delayed(Duration(seconds: currentRetry * 2));
      }
    }
    
    throw Exception('Error inesperado al inicializar chat');
  }

  /// Subir imagen como volatile knowledge y obtener ID inmediatamente
  Future<String> uploadImageToVolatileKnowledge(
    html.File file,
    {Function(String)? onStatusUpdate}
  ) async {
    int maxRetries = 3;
    int currentRetry = 0;
    
    while (currentRetry < maxRetries) {
      try {
        print('=== UPLOAD ATTEMPT ${currentRetry + 1} ===');
        print('URL: ${AppConfig.volatileKnowledgeUrl}');
        print('File: ${file.name}, Size: ${file.size} bytes');
        
        onStatusUpdate?.call('Subiendo imagen...');
        
        final formData = html.FormData();
        
        // Usar callback placeholder
        final uniqueId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final placeholderCallback = 'https://placeholder.callback.url/$uniqueId';
        formData.append('CallbackUrl', placeholderCallback);
        
        print('Callback URL: $placeholderCallback');
        
        // Solo enviar el archivo
        formData.appendBlob('File', file, file.name);
        
        final request = html.HttpRequest();
        request.open('POST', AppConfig.volatileKnowledgeUrl);
        request.setRequestHeader('X-API-KEY', AppConfig.iaApiKey);
        
        print('Headers configurados, enviando request...');
        
        // Crear completer para manejar la respuesta async
        final completer = Completer<String>();
        
        request.onLoadEnd.listen((e) {
          print('=== UPLOAD RESPONSE ===');
          print('Status: ${request.status}');
          print('Response: ${request.responseText}');
          
          if (request.status == 200 && request.responseText != null) {
            try {
              final responseData = json.decode(request.responseText!);
              final volatileKnowledgeId = responseData['id'] ?? '';
              
              print('Parsed ID: $volatileKnowledgeId');
              
              if (volatileKnowledgeId.isEmpty) {
                completer.completeError('No se recibió ID del volatile knowledge');
                return;
              }
              
              onStatusUpdate?.call('Imagen subida correctamente');
              completer.complete(volatileKnowledgeId);
              
            } catch (e) {
              print('Error parsing response: $e');
              completer.completeError('Error parsing response: $e');
            }
          } else {
            print('HTTP Error - Status: ${request.status}, Response: ${request.responseText}');
            completer.completeError('HTTP ${request.status}: ${request.responseText}');
          }
        });
        
        request.onError.listen((e) {
          print('=== NETWORK ERROR ===');
          print('Error: $e');
          completer.completeError('Network error: $e');
        });
        
        request.onTimeout.listen((e) {
          print('=== REQUEST TIMEOUT ===');
          completer.completeError('Request timeout');
        });
        
        // Configurar timeout
        request.timeout = 60000; // 1 minuto para upload
        
        // Enviar la request
        request.send(formData);
        
        // Esperar la respuesta
        return await completer.future;
        
      } catch (e) {
        print('=== UPLOAD RETRY ===');
        print('Retry $currentRetry/$maxRetries - Error: $e');
        
        currentRetry++;
        if (currentRetry >= maxRetries) {
          throw Exception('Error al subir imagen después de $maxRetries intentos: $e');
        }
        
        // Esperar antes del siguiente intento
        print('Esperando ${currentRetry * 2} segundos antes del siguiente intento...');
        await Future.delayed(Duration(seconds: currentRetry * 2));
      }
    }
    
    throw Exception('Error inesperado al subir imagen');
  }

  /// Ejecutar análisis usando el agente de Nestlé con chatId
  Future<AnalysisResponse> executeAnalysis(String chatId, String fileId) async {
    int maxRetries = 3;
    int currentRetry = 0;
    
    while (currentRetry < maxRetries) {
      try {
  final uri = Uri.parse(AppConfig.iaApiBaseUrl + AppConfig.nestleCheckAgentEndpoint);
        
        final headers = {
          'Content-Type': 'application/json',
          'X-API-KEY': AppConfig.iaApiKey,
        };
        
        final body = json.encode([
          {
            "key": "chatId",
            "value": chatId
          },
          {
            "key": "message",
            "value": "Analiza esta imagen según los estándares de Nestlé"
          },
          {
            "key": "volatileKnowledgeIds",
            "value": [fileId]
          }
        ]);
        
        final response = await http.post(
          uri, 
          headers: headers, 
          body: body,
        ).timeout(const Duration(seconds: 600)); // Timeout de 10 minutos para análisis
        
        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          return AnalysisResponse.fromJson(jsonData);
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        currentRetry++;
        if (currentRetry >= maxRetries) {
          throw Exception('Error al ejecutar análisis después de $maxRetries intentos: $e');
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
  final List<ExecutorTaskLog> executorTaskLogs;

  AnalysisResponse({
    required this.content,
    this.jsonContent,
    this.metaAnalysis,
    required this.violations,
    required this.timeToFirstToken,
    required this.instanceId,
    required this.executorTaskLogs,
  });

  factory AnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisResponse(
      content: json['content'] ?? '',
      jsonContent: json['jsonContent'],
      metaAnalysis: json['metaAnalysis'],
      violations: List<dynamic>.from(json['violations'] ?? []),
      timeToFirstToken: json['timeToFirstToken'] ?? 0,
      instanceId: json['instanceId'] ?? '',
      executorTaskLogs: (json['executorTaskLogs'] as List<dynamic>?)
          ?.map((log) => ExecutorTaskLog.fromJson(log))
          .toList() ?? [],
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
      'executorTaskLogs': executorTaskLogs.map((log) => log.toJson()).toList(),
    };
  }
}

/// Modelo para los logs de ejecución
class ExecutorTaskLog {
  final String key;
  final String description;
  final int duration;
  final bool success;

  ExecutorTaskLog({
    required this.key,
    required this.description,
    required this.duration,
    required this.success,
  });

  factory ExecutorTaskLog.fromJson(Map<String, dynamic> json) {
    return ExecutorTaskLog(
      key: json['key'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? 0,
      success: json['success'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'description': description,
      'duration': duration,
      'success': success,
    };
  }
}

