import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../widgets/chat_component.dart';


class AnalysisResult extends StatefulWidget {
  final String projectName;

  const AnalysisResult({
    super.key,
    required this.projectName,
  });

  @override
  State<AnalysisResult> createState() => _AnalysisResultState();
}

class _AnalysisResultState extends State<AnalysisResult> {
  bool isCollapsed = false;
  bool _isLoading = true;
  Map<String, dynamic>? _analysisData;

  @override
  void initState() {
    super.initState();
    _loadAnalysisResults();
  }




  Future<void> _loadAnalysisResults() async {
    // Simular carga de datos del análisis
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isLoading = false;
      _analysisData = {
        'projectName': widget.projectName,
        'analysisDate': DateTime.now(),
        'totalImages': 15,
        'validImages': 12,
        'invalidImages': 3,
        'complianceScore': 85,
        'issues': [
          {
            'type': 'Logo Position',
            'severity': 'Medium',
            'count': 2,
            'description': 'Logo no está centrado correctamente'
          },
          {
            'type': 'Color Compliance',
            'severity': 'Low',
            'count': 1,
            'description': 'Variación menor en tonalidad del logo'
          },
        ],
        'recommendations': [
          'Revisar posicionamiento del logo en las imágenes señaladas',
          'Verificar calibración de color en el proceso de impresión',
          'Considerar establecer guías más claras para el posicionamiento'
        ]
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isCollapsed ? 70 : 220,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Botón para colapsar/expandir
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      isCollapsed ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                      size: 18,
                      color: const Color(0xFF004B93),
                    ),
                    onPressed: () {
                      setState(() {
                        isCollapsed = !isCollapsed;
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Logo
                if (!isCollapsed) ...[
                  Container(
                    width: 120,
                    height: 60,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/NestléLogo.svg.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/NestléLogo.svg.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 40),
                
                // Opciones del menú
                _buildMenuItem(
                  icon: Icons.home,
                  label: 'Inicio',
                  onTap: () => context.go('/home'),
                ),
                _buildMenuItem(
                  icon: Icons.add_circle,
                  label: 'Nuevo Análisis',
                  onTap: () => context.go('/new-art'),
                ),
                _buildMenuItem(
                  icon: Icons.analytics,
                  label: 'Resultados',
                  onTap: () {},
                  isSelected: true,
                ),
                
                const Spacer(),
                
                // Botón de logout
                _buildMenuItem(
                  icon: Icons.logout,
                  label: 'Cerrar Sesión',
                  onTap: () => context.go('/login'),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // Contenido principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF004B93)),
                        onPressed: () => context.go('/home'),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Resultados del Análisis',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: const Color(0xFF004B93),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Proyecto: ${widget.projectName}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
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
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : const Color(0xFF004B93),
          size: 20,
        ),
        title: isCollapsed
            ? null
            : Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF004B93),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
        tileColor: isSelected ? const Color(0xFF004B93) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: onTap,
        dense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCollapsed ? 8 : 16,
          vertical: 4,
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
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Botones de acción
          _buildActionButtons(),
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
            'Imágenes Válidas',
            _analysisData!['validImages'].toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Problemas',
            _analysisData!['invalidImages'].toString(),
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
    Color severityColor;
    switch (issue['severity']) {
      case 'High':
        severityColor = Colors.red;
        break;
      case 'Medium':
        severityColor = Colors.orange;
        break;
      case 'Low':
        severityColor = Colors.yellow[700]!;
        break;
      default:
        severityColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(width: 4, color: severityColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      issue['type'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        issue['severity'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  issue['description'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${issue['count']} casos',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
                            entry.value,
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

  void _exportReport() {
    if (_analysisData == null) return;

    // Construir CSV
    final buffer = StringBuffer();
    buffer.writeln('Proyecto,Fecha,Imágenes Totales,Imágenes Válidas,Problemas,Puntaje');
    buffer.writeln('${_analysisData!['projectName']},${_analysisData!['analysisDate']},${_analysisData!['totalImages']},${_analysisData!['validImages']},${_analysisData!['invalidImages']},${_analysisData!['complianceScore']}%');
    buffer.writeln();
    buffer.writeln('Tipo de Problema,Severidad,Cantidad,Descripción');
    for (final issue in _analysisData!['issues']) {
      buffer.writeln('${issue['type']},${issue['severity']},${issue['count']},${issue['description']}');
    }
    buffer.writeln();
    buffer.writeln('Recomendaciones');
    for (final rec in _analysisData!['recommendations']) {
      buffer.writeln(rec);
    }

    final bytes = utf8.encode(buffer.toString());
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'reporte_${_analysisData!['projectName']}.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reporte exportado exitosamente')),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _exportReport,
          icon: const Icon(Icons.download),
          label: const Text('Exportar Reporte'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF004B93),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () => context.go('/new-art'),
          icon: const Icon(Icons.refresh),
          label: const Text('Nuevo Análisis'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF004B93),
            side: const BorderSide(color: Color(0xFF004B93)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }


}