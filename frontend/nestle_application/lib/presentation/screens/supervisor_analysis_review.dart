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
  String _reviewComment = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAnalysisData();
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
    final caseData = await CasesService().getCaseById(widget.caseId!);
    setState(() {
      _isLoading = false;
      _analysisData = caseData;
      // Si hay imagen subida, seleccionarla
      if (_analysisData != null && _analysisData!['lastUploadedImage'] != null) {
        _selectedImageUrl = _analysisData!['lastUploadedImage']['url'];
      } else {
        _selectedImageUrl = null;
      }
    });
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
    setState(() {
      _isSubmitting = true;
    });

    // Simular envío de decisión
    await Future.delayed(const Duration(seconds: 2));

    // Log del comentario para debugging (en producción esto se enviaría al backend)
    print('Decisión: ${approved ? 'Aprobado' : 'Rechazado'}');
    if (_reviewComment.isNotEmpty) {
      print('Comentario: $_reviewComment');
    }

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
            
            // Layout principal con dos columnas
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna izquierda: Imagen y detalles
                Expanded(
                  flex: 2,
                  child: _buildImageSection(),
                ),
                
                const SizedBox(width: 24),
                
                // Columna derecha: Problemas y recomendaciones
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildProblemsSection(),
                      const SizedBox(height: 16),
                      _buildRecommendationsSection(),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Sección de decisión
            _buildDecisionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_open,
                  color: const Color(0xFF004B93),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Proyecto: ${_analysisData!['name']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004B93),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Usuario:',
                    _analysisData!['user_name'],
                    Icons.person,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Email:',
                    _analysisData!['user_email']?.toString() ?? '',
                    Icons.email,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Enviado:',
                    _formatDate(_analysisData!['created_at']),
                    Icons.schedule,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Imágenes Totales',
            _analysisData!['total_images'].toString(),
            Icons.image,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Válidas',
            _analysisData!['valid_images'].toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Problemas',
            _analysisData!['issues_found'].toString(),
            Icons.warning,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Puntuación IA',
            '${_analysisData!['score']}%',
            Icons.psychology,
            (_analysisData!['score'] ?? 0) >= 80 ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final imageData = _analysisData!['lastUploadedImage'];
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Última Imagen Subida',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004B93),
              ),
            ),
            const SizedBox(height: 16),
            
            // Imagen principal
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _selectedImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Información de la imagen
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Archivo: ${imageData['name']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tamaño: ${imageData['size']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Subido: ${_formatDate(imageData['uploadDate'])}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Función para ver imagen en tamaño completo
                    _showFullScreenImage(context, _selectedImageUrl!);
                  },
                  icon: const Icon(Icons.fullscreen),
                  label: const Text('Ver completa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004B93),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemsSection() {
  final problems = (_analysisData!['problems']?['issues'] ?? []) as List;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Problemas Detectados',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004B93),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: problems.isEmpty
                ? Center(
                    child: Text(
                      'No se detectaron problemas',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: problems.length,
                    itemBuilder: (context, index) {
                      final problem = problems[index];
                      return _buildProblemItem(problem);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemItem(Map<String, dynamic> problem) {
    Color severityColor;
    switch (problem['severity']) {
      case 'Alto':
        severityColor = Colors.red;
        break;
      case 'Medio':
        severityColor = Colors.orange;
        break;
      case 'Bajo':
        severityColor = Colors.yellow[700]!;
        break;
      default:
        severityColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(width: 4, color: severityColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                problem['type'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  problem['severity'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            problem['description'],
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Afecta: ${(problem['affectedImages'] as List).join(', ')}',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
              fontStyle: FontStyle.italic,
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
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recomendaciones IA',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004B93),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: recommendations.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
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
                            recommendations[index],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Decisión del Supervisor',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004B93),
              ),
            ),
            const SizedBox(height: 16),
            
            // Campo de comentarios
            TextField(
              onChanged: (value) {
                setState(() {
                  _reviewComment = value;
                });
              },
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Comentarios adicionales (opcional)',
                hintText: 'Agregue cualquier observación o comentario sobre la revisión...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF004B93)),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botones de decisión
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : () => _handleDecision(false),
                    icon: _isSubmitting 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.close),
                    label: Text(_isSubmitting ? 'Procesando...' : 'Rechazar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : () => _handleDecision(true),
                    icon: _isSubmitting 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                    label: Text(_isSubmitting ? 'Procesando...' : 'Aprobar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Botón de cancelar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => context.go('/home'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF004B93),
                  side: const BorderSide(color: Color(0xFF004B93)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}