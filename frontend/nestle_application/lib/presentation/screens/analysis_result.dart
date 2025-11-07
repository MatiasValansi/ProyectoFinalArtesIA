import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../widgets/chat_component.dart';
import '../../core/auth/auth_service.dart';
import '../../database/cases_service.dart';

class AnalysisResult extends StatefulWidget {
  final String projectName;
  final String? serenityId;

  const AnalysisResult({super.key, required this.projectName, this.serenityId});

  @override
  State<AnalysisResult> createState() => _AnalysisResultState();
}

class _AnalysisResultState extends State<AnalysisResult> {
  bool _isLoading = true;
  Map<String, dynamic>? _analysisData;
  final AuthService _authService = AuthService();
  final CasesService _casesService = CasesService();
  List<String> _imageUrls = [];
  int _currentImageIndex = 0;

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
      final cases = await _casesService.getCasesBySerenityId(
        widget.serenityId!,
      );
      if (cases.isNotEmpty) {
        final caseData = cases.first;

        // Procesar problemas
        List<Map<String, dynamic>> issuesList = [];
        final problems = caseData['problems'];
        if (problems != null) {
          if (problems is List) {
            for (final problem in problems) {
              if (problem is Map<String, dynamic>) {
                issuesList.add({
                  'type': problem['titulo'] ?? 'Problema',
                  'description': problem['detalle'] ?? 'Sin descripción',
                });
              }
            }
          } else if (problems is Map) {
            for (final value in problems.values) {
              if (value is Map<String, dynamic>) {
                issuesList.add({
                  'type': value['titulo'] ?? 'Problema',
                  'description': value['detalle'] ?? 'Sin descripción',
                });
              }
            }
          }
        }

        // Procesar recomendaciones (solo listas de strings)
        List<String> recommendationsList = [];
        if (caseData['recommendations'] is List) {
          final recommendationsArray =
              caseData['recommendations'] as List<dynamic>;
          for (final recommendation in recommendationsArray) {
            if (recommendation is String && recommendation.isNotEmpty) {
              recommendationsList.add(recommendation);
            }
          }
        }
        final arteIdArray = caseData['arte_id'] as List<dynamic>? ?? [];
        final totalImages = arteIdArray.length;

        // Obtener URLs de las imágenes
        List<String> imageUrls = [];

        if (caseData['image_urls'] != null) {
          final imageUrlsData = caseData['image_urls'];
          if (imageUrlsData is List) {
            for (final url in imageUrlsData) {
              if (url is String && url.isNotEmpty) {
                imageUrls.add(url);
              }
            }
          }
        }

        // Solo hacer setState si el widget está montado
        if (mounted) {
          setState(() {
            _isLoading = false;
            _imageUrls = imageUrls.reversed.toList();
            _currentImageIndex = 0;
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
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _analysisData = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _analysisData = null;
        });
      }
      throw ('Error cargando análisis: $e');
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        context.pushReplacement('/login');
      }
    } catch (e) {
      throw ('Error al cerrar sesión: $e');
    }
  }

  /// Callback cada vez que la IA responde
  Future<void> _handleAnalysisUpdate() async {
    try {
      await _loadAnalysisResultsFromDB();
      if (_imageUrls.isNotEmpty && mounted) {
        setState(() {
          _currentImageIndex = 0;
        });
      } else {}
    } catch (e) {
      throw ('Error: $e');
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          CircularProgressIndicator(color: Color(0xFF004B93)),
          SizedBox(height: 16),
          Text(
            'Analizando resultados...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
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

          SizedBox(
            height: 600,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Problemas y Recomendaciones juntos
                Expanded(
                  flex: 1,
                  child: _buildProblemsAndRecommendationsSection(),
                ),

                const SizedBox(width: 16),

                // Imagen
                Expanded(flex: 1, child: _buildImageSection()),

                const SizedBox(width: 16),

                // Chat
                Expanded(
                  flex: 1,
                  child: ChatComponent(
                    projectName: widget.projectName,
                    analysisData: _analysisData,
                    caseSerenityId: widget.serenityId,
                    onAnalysisUpdated: _handleAnalysisUpdate,
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
            _analysisData!['complianceScore'] >= 80
                ? Colors.green
                : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildProblemsAndRecommendationsSection() {
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
            'Análisis de Calidad',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF004B93),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección de Problemas
                  Text(
                    'Problemas Encontrados',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(_analysisData!['issues'] as List).map(
                    (issue) => _buildIssueItem(issue),
                  ),

                  const SizedBox(height: 24),

                  // Recomendaciones
                  Text(
                    'Recomendaciones',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(_analysisData!['recommendations'] as List)
                      .asMap()
                      .entries
                      .map(
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
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_imageUrls.length > 1)
                IconButton(
                  onPressed: _currentImageIndex > 0
                      ? () {
                          setState(() {
                            _currentImageIndex--;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back_ios),
                ),
              Text(
                'Imágenes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF004B93),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_imageUrls.length > 1)
                IconButton(
                  onPressed: _currentImageIndex < _imageUrls.length - 1
                      ? () {
                          setState(() {
                            _currentImageIndex++;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward_ios),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _imageUrls.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _imageUrls[_currentImageIndex],
                      fit: BoxFit.contain,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.broken_image,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No se pudo cargar la imagen',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF004B93),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Imagen no disponible',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
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
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
    return recommendation.toString().trim();
  }
}
