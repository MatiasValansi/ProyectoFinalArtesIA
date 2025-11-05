import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_service.dart';
import '../../database/cases_service.dart';

class SupervisorAnalysisReview extends StatefulWidget {
  final String projectName;
  final String? serenityId;
  final String? caseId;

  const SupervisorAnalysisReview({
    super.key,
    required this.projectName,
    this.serenityId,
    this.caseId,
  });

  @override
  State<SupervisorAnalysisReview> createState() => _SupervisorAnalysisReviewState();
}

class _SupervisorAnalysisReviewState extends State<SupervisorAnalysisReview> {
  bool _isLoading = true;
  Map<String, dynamic>? _analysisData;
  final AuthService _authService = AuthService();
  String? _selectedImageUrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAnalysisData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadAnalysisData() async {
    // Simular carga de datos del análisis
    await Future.delayed(const Duration(seconds: 1));
    
    if (widget.caseId == null) {
      setState(() {
        _isLoading = false;
        _analysisData = null;
      });
      return;
    }
    
    try {
      // Primero intentar obtener con información del usuario
      final allCases = await CasesService().getAllCasesWithUserInfo();
      final caseData = allCases.firstWhere(
        (caseItem) => caseItem['id']?.toString() == widget.caseId,
        orElse: () => <String, dynamic>{},
      );
      
      if (caseData.isEmpty) {
        // Si no se encuentra en la lista, usar el método directo
        final directCaseData = await CasesService().getCaseById(widget.caseId!);
        final adaptedData = _adaptCaseData(directCaseData);
        setState(() {
          _isLoading = false;
          _analysisData = adaptedData;
          _setSelectedImage();
        });
      } else {
        final adaptedData = _adaptCaseData(caseData);
        setState(() {
          _isLoading = false;
          _analysisData = adaptedData;
          _setSelectedImage();
        });
      }
    } catch (e) {
      print('Error cargando datos del caso: $e');
      setState(() {
        _isLoading = false;
        _analysisData = null;
      });
    }
  }

  Map<String, dynamic>? _adaptCaseData(Map<String, dynamic>? caseData) {
    if (caseData == null) return null;
    
    
    final userInfo = caseData['user_id'];
    return {
      ...caseData,
      'user_name': userInfo is Map ? _extractUsernameFromEmail(userInfo['email']?.toString()) : 'Usuario desconocido',
      'user_email': userInfo is Map ? userInfo['email']?.toString() ?? 'email@desconocido.com' : 'email@desconocido.com',
      // Asegurar que los campos requeridos existan
      'name': caseData['name']?.toString() ?? 'Proyecto sin nombre',
      'total_images': caseData['total_images'] ?? 0,
      'valid_images': caseData['valid_images'] ?? 0,
      'score': caseData['score'] ?? 0,
      'problems': caseData['problems'] ?? [],
      'recommendations': caseData['recommendations'] ?? [],
      'image_urls': caseData['image_urls'] ?? [],
    };
  }

  String _extractUsernameFromEmail(String? email) {
    if (email == null || email.isEmpty) return 'Usuario';
    final parts = email.split('@');
    return parts.isNotEmpty ? parts.first : 'Usuario';
  }

  void _setSelectedImage() {
    // Primero verificar si hay URLs de imagen en Supabase (usar la primera del array)
    if (_analysisData != null && _analysisData!['image_urls'] != null) {
      final imageUrls = _analysisData!['image_urls'] as List?;
      if (imageUrls != null && imageUrls.isNotEmpty) {
        // Tomar la primera URL (la más reciente si se está guardando en orden)
        _selectedImageUrl = imageUrls.first.toString();
        return;
      }
    }
    // Fallback a la imagen subida anteriormente
    if (_analysisData != null && _analysisData!['lastUploadedImage'] != null) {
      final imageData = _analysisData!['lastUploadedImage'];
      _selectedImageUrl = imageData is Map ? imageData['url']?.toString() : null;
    } else {
      _selectedImageUrl = null;
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

  Future<void> _handleDecision(bool approved) async {
    if (widget.caseId == null) return;
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Actualizar el campo approved del caso en la base de datos
      await CasesService().updateCaseApprovalStatus(widget.caseId!, approved);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approved 
                ? 'Arte aprobado exitosamente' 
                : 'Arte rechazado. El usuario será notificado.',
            ),
            backgroundColor: approved ? Colors.green : Colors.red,
          ),
        );
        
        setState(() {
          _isSubmitting = false;
        });
        
        // Regresar a la pantalla anterior después de un breve delay
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      print('Error al actualizar el estado del caso: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la decisión: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
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
          'Revisión de Análisis - Supervisor',
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
      body: _isLoading 
        ? _buildLoadingWidget() 
        : _buildContent(),
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
            'Cargando datos del análisis...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_analysisData == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con información del proyecto
            _buildProjectHeader(),
            
            const SizedBox(height: 24),
            
            // Cards de resumen
            _buildSummaryCards(),
            
            const SizedBox(height: 24),
            
            // Layout principal con tres columnas
            SizedBox(
              height: 600, // Altura fija para evitar problemas de layout
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna 1: Imagen
                  Expanded(
                    flex: 1,
                    child: _buildImageSection(),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Columna 2: Problemas
                  Expanded(
                    flex: 1,
                    child: _buildProblemsSection(),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Columna 3: Recomendaciones y Botones de decisión
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildRecommendationsSection(),
                        ),
                        const SizedBox(height: 16),
                        _buildDecisionButtons(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildProjectHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF004B93).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.folder_open,
                  color: Color(0xFF004B93),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _analysisData!['name']?.toString() ?? 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004B93),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Usuario',
                  _analysisData!['user_name']?.toString() ?? 'Usuario desconocido',
                  Icons.person,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Email',
                  _analysisData!['user_email']?.toString() ?? '',
                  Icons.email,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Fecha de envío',
                  _analysisData!['created_at']?.toString() != null 
                    ? _formatDate(DateTime.parse(_analysisData!['created_at'].toString()))
                    : 'Fecha no disponible',
                  Icons.schedule,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon, 
                size: 18, 
                color: const Color(0xFF004B93),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    // Obtener el número de imágenes desde arte_id array
    final arteIdArray = _analysisData!['arte_id'] as List<dynamic>? ?? [];
    final totalImages = arteIdArray.length;
    
    // Calcular problemas desde la nueva estructura
    int issuesCount = 0;
    if (_analysisData!['problems'] != null) {
      if (_analysisData!['problems'] is List) {
        issuesCount = (_analysisData!['problems'] as List).length;
      } else if (_analysisData!['problems'] is Map && _analysisData!['problems']['issues'] != null) {
        issuesCount = (_analysisData!['problems']['issues'] as List).length;
      }
    }
    
    final score = _analysisData!['score']?.toInt() ?? 0;
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Imágenes Totales',
            totalImages.toString(),
            Icons.image,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Problemas',
            issuesCount.toString(),
            Icons.error,
            Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Puntuación',
            '${score}%',
            Icons.analytics,
            score >= 80 ? Colors.green : Colors.orange,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Imagen del Proyecto',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF004B93),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _selectedImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _selectedImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Error cargando imagen'),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, 
                               size: 48, 
                               color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No hay imagen disponible'),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemsSection() {
    List problems = [];
    if (_analysisData!['problems'] != null) {
      if (_analysisData!['problems'] is List) {
        problems = _analysisData!['problems'] as List;
      } else if (_analysisData!['problems'] is Map && _analysisData!['problems']['issues'] != null) {
        problems = (_analysisData!['problems']['issues'] ?? []) as List;
      }
    }
    
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
            'Problemas Detectados',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF004B93),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: problems.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, 
                             size: 48, 
                             color: Colors.green),
                        SizedBox(height: 8),
                        Text('No hay problemas detectados'),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: problems.map((problem) => _buildProblemItem(problem)).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemItem(dynamic problemData) {
    Map<String, dynamic> problem;
    
    if (problemData is Map<String, dynamic>) {
      problem = problemData;
    } else if (problemData is String) {
      problem = {'titulo': 'Problema', 'detalle': problemData};
    } else {
      problem = {'titulo': 'Problema', 'detalle': 'Sin descripción'};
    }

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
                  problem['titulo']?.toString() ?? 'Problema detectado',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF004B93),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  problem['detalle']?.toString() ?? 'Sin descripción disponible',
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

  Widget _buildRecommendationsSection() {
    final recommendations = (_analysisData!['recommendations'] is List)
      ? _analysisData!['recommendations'] as List
      : (_analysisData!['recommendations'] != null
        ? [_analysisData!['recommendations']] : []);
    
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
          Text(
            'Recomendaciones IA',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF004B93),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: recommendations.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lightbulb_outline, 
                             size: 48, 
                             color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No hay recomendaciones'),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: recommendations.asMap().entries.map(
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
                                  entry.value.toString(),
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

  Widget _buildDecisionButtons() {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Decisión del Supervisor',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF004B93),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : () => _handleDecision(true),
            icon: const Icon(Icons.check_circle, color: Colors.white),
            label: Text(_isSubmitting ? 'Procesando...' : 'APROBAR ARTE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : () => _handleDecision(false),
            icon: const Icon(Icons.cancel, color: Colors.white),
            label: Text(_isSubmitting ? 'Procesando...' : 'RECHAZAR ARTE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver al inicio'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}