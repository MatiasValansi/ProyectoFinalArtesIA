import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../widgets/chat_component.dart';
import '../../core/auth/auth_service.dart';
import '../../database/cases_service.dart';


class AnalysisResult extends StatefulWidget {
  final String projectName;
  final String? serenityId;

  const AnalysisResult({
    super.key,
    required this.projectName,
    this.serenityId,
  });

  @override
  State<AnalysisResult> createState() => _AnalysisResultState();
}

class _AnalysisResultState extends State<AnalysisResult> {
  bool _isLoading = true;
  Map<String, dynamic>? _analysisData;
  final AuthService _authService = AuthService();
  final CasesService _casesService = CasesService();

  @override
  void initState() {
  super.initState();
  _loadAnalysisResultsFromDB();
  }




  Future<void> _loadAnalysisResultsFromDB() async {
    if (widget.serenityId == null) {
      setState(() {
        _isLoading = false;
        _analysisData = null;
      });
      return;
    }
    try {
      final cases = await _casesService.getCasesBySerenityId(widget.serenityId!);
      if (cases.isNotEmpty) {
        final caseData = cases.first;
        
        // Procesar problemas del nuevo formato del agente (ahora es un array)
        List<Map<String, dynamic>> issuesList = [];
        if (caseData['problems'] != null) {
          if (caseData['problems'] is List) {
            // Nuevo formato: array de problemas
            final problemsArray = caseData['problems'] as List<dynamic>;
            for (final problem in problemsArray) {
              if (problem is Map<String, dynamic>) {
                issuesList.add({
                  'type': problem['titulo'] ?? 'Problema',
                  'description': problem['detalle'] ?? 'Sin descripción',
                  'severity': problem['severity'] ?? 'Medium',
                });
              }
            }
          } else if (caseData['problems'] is Map) {
            // Formato anterior: objeto de problemas (por compatibilidad)
            final problems = caseData['problems'] as Map<String, dynamic>;
            problems.forEach((key, value) {
              if (value is Map<String, dynamic> && value.containsKey('titulo') && value.containsKey('detalle')) {
                issuesList.add({
                  'type': value['titulo'] ?? 'Problema',
                  'description': value['detalle'] ?? 'Sin descripción',
                  'severity': 'Medium',
                });
              }
            });
          }
        }
        
        // Procesar recomendaciones (ahora es un array de strings simples)
        List<String> recommendationsList = [];
        if (caseData['recommendations'] != null) {
          print('🔍 Tipo de recommendations: ${caseData['recommendations'].runtimeType}');
          print('🔍 Contenido: ${caseData['recommendations']}');
          
          if (caseData['recommendations'] is List) {
            // Nuevo formato: array de strings simples
            final recommendationsArray = caseData['recommendations'] as List<dynamic>;
            for (final recommendation in recommendationsArray) {
              if (recommendation is String && recommendation.isNotEmpty) {
                recommendationsList.add(recommendation);
              } else {
                // Para compatibilidad con formato anterior (objetos con 'text')
                if (recommendation is Map<String, dynamic> && recommendation['text'] != null) {
                  recommendationsList.add(recommendation['text'].toString());
                } else {
                  // Convertir a string y agregar si no está vacío
                  final recText = recommendation.toString();
                  if (recText.isNotEmpty && recText != 'null') {
                    recommendationsList.add(recText);
                  }
                }
              }
            }
          } else if (caseData['recommendations'] is String && caseData['recommendations'].toString().isNotEmpty) {
            // Formato anterior: texto (por compatibilidad)
            final recommendations = caseData['recommendations'].toString();
            
            // Verificar si es un JSON string que necesita ser parseado
            if (recommendations.startsWith('{') || recommendations.startsWith('[')) {
              try {
                final parsed = jsonDecode(recommendations);
                if (parsed is Map) {
                  // Si es un mapa, extraer los valores
                  parsed.values.forEach((value) {
                    if (value.toString().isNotEmpty) {
                      recommendationsList.add(value.toString());
                    }
                  });
                } else if (parsed is List) {
                  // Si es una lista, procesar cada elemento
                  for (final item in parsed) {
                    if (item.toString().isNotEmpty) {
                      recommendationsList.add(item.toString());
                    }
                  }
                }
              } catch (e) {
                // Si falla el parsing, usar como texto normal
                recommendationsList = recommendations
                    .split('\n')
                    .where((rec) => rec.trim().isNotEmpty)
                    .map((rec) => rec.trim())
                    .toList();
              }
            } else {
              // Dividir por líneas si contiene saltos de línea
              recommendationsList = recommendations
                  .split('\n')
                  .where((rec) => rec.trim().isNotEmpty)
                  .map((rec) => rec.trim().replaceAll('• ', ''))
                  .toList();
            }
          }
        }
        final arteIdArray = caseData['arte_id'] as List<dynamic>? ?? [];
        final totalImages = arteIdArray.length;

        setState(() {
          _isLoading = false;
          _analysisData = {
            'projectName': caseData['name'],
            'analysisDate': caseData['created_at'],
            'totalImages': totalImages,
            'invalidImages': issuesList.length, 
            'complianceScore': caseData['score'] ?? 0,
            'issues': issuesList,
            'recommendations': recommendationsList,
          };
        });
      } else {
        setState(() {
          _isLoading = false;
          _analysisData = null;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _analysisData = null;
      });
      print('Error cargando análisis: $e');
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        context.pushReplacement('/login');
      }
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: const Color(0xFF004B93),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.go('/home');
          },
        ),
        title: const Text(
          'Resultados del Análisis - Nestlé Validation Tool',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF004B93),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y subtítulo
            Text(
              'Proyecto: ${widget.projectName}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004B93),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Contenido
            Expanded(
              child: _isLoading
                  ? _buildLoadingWidget()
                  : _buildAnalysisContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF004B93),
          ),
          SizedBox(height: 16),
          Text(
            'Analizando resultados...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisContent() {
    if (_analysisData == null) return const SizedBox();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen general
          _buildSummaryCards(),
          
          const SizedBox(height: 32),
          
          // Layout de 3 columnas: Problemas, Recomendaciones y Chat
          SizedBox(
            height: 600, // Altura fija para evitar problemas de layout
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna 1: Problemas encontrados
                Expanded(
                  flex: 1,
                  child: _buildIssuesSection(),
                ),
                
                const SizedBox(width: 16),
                
                // Columna 2: Recomendaciones
                Expanded(
                  flex: 1,
                  child: _buildRecommendationsSection(),
                ),
                
                const SizedBox(width: 16),
                
                // Columna 3: Chat con IA
                Expanded(
                  flex: 1,
                  child: ChatComponent(
                    projectName: widget.projectName,
                    analysisData: _analysisData,
                    caseSerenityId: widget.serenityId,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Imágenes Totales',
            _analysisData!['totalImages'].toString(),
            Icons.image,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Problemas',
            (_analysisData!['issues'] as List).length.toString(),
            Icons.error,
            Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Puntuación',
            '${_analysisData!['complianceScore']}%',
            Icons.analytics,
            _analysisData!['complianceScore'] >= 80 ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesSection() {
    return Container(
      height: 600,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Problemas Encontrados',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF004B93),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: (_analysisData!['issues'] as List).map((issue) => _buildIssueItem(issue)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueItem(Map<String, dynamic> issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(width: 4, color: Colors.orange)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue['type'] ?? 'Problema detectado',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF004B93),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  issue['description'] ?? 'Sin descripción disponible',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _parseRecommendationText(dynamic recommendation) {
    if (recommendation == null) return 'Sin recomendación disponible';
    
    // Como ahora solo extraemos el campo 'text' en el procesamiento,
    // esta función solo necesita limpiar el string
    return recommendation.toString().trim();
  }

  Widget _buildRecommendationsSection() {
    return Container(
      height: 600,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recomendaciones',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF004B93),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: (_analysisData!['recommendations'] as List).asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF004B93),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _parseRecommendationText(entry.value),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}