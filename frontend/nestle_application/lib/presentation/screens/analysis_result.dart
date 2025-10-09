import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;

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
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  List<Map<String, dynamic>> _chatMessages = [];
  String? _chatInstanceId;
  bool _isChatInitializing = false;
  bool _isChatSending = false;
  html.File? _selectedImage;
  String? _selectedImageBase64;

  @override
  void initState() {
    super.initState();
    _loadAnalysisResults();
    _initializeChatMessages();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _initializeChatMessages() {
    _chatMessages = [
      {
        'isUser': false,
        'message': 'Inicializando asistente de Nestlé...',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 1)),
        'isLoading': true,
      },
    ];
    _initializeChatAgent();
  }

  Future<void> _initializeChatAgent() async {
    setState(() {
      _isChatInitializing = true;
    });

    try {
      final requestBody = [
        {
          'key': 'message',
          'value': '',
        }
      ];
      
      print('Iniciando chat con cuerpo: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('https://api.serenitystar.ai/api/v2/agent/NestleCheckAsistente/execute'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': '10472b86-76cf-41d4-a27e-7fe76745d7db',
        },
        body: jsonEncode(requestBody),
      );

      print('Respuesta del servidor - Status: ${response.statusCode}');
      print('Respuesta del servidor - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _chatInstanceId = data['instanceId'];
        
        print('Instance ID obtenido: $_chatInstanceId');
        
        setState(() {
          // Remover mensaje de carga y agregar mensaje de bienvenida
          _chatMessages.removeWhere((msg) => msg['isLoading'] == true);
          _chatMessages.add({
            'isUser': false,
            'message': data['content'] ?? '¡Hola! Soy tu asistente de análisis de Nestlé. ¿En qué puedo ayudarte con los resultados del análisis?',
            'timestamp': DateTime.now(),
            'isLoading': false,
          });
          _isChatInitializing = false;
        });
      } else {
        print('Error HTTP ${response.statusCode}: ${response.body}');
        
        // Si es error 400, intentar con mensaje aún más simple
        if (response.statusCode == 400) {
          print('Reintentando con mensaje simple...');
          await _retryInitialization();
          return;
        }
        
        throw Exception('Error al inicializar el chat: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _chatMessages.removeWhere((msg) => msg['isLoading'] == true);
        _chatMessages.add({
          'isUser': false,
          'message': 'No se pudo conectar con el asistente. Funcionando en modo offline.',
          'timestamp': DateTime.now(),
          'isLoading': false,
        });
        _isChatInitializing = false;
      });
      print('Error inicializando chat: $e');
    }
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
                  child: _buildChatSection(),
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Implementar exportar reporte
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Funcionalidad de exportar en desarrollo')),
            );
          },
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

  Widget _buildChatSection() {
    return Container(
      height: 600, // Altura fija para el chat
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
        children: [
          // Header del chat
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF004B93),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Asistente IA de Análisis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isChatInitializing 
                        ? Colors.orange 
                        : (_chatInstanceId != null ? Colors.green : Colors.red),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isChatInitializing 
                      ? 'Conectando...' 
                      : (_chatInstanceId != null ? 'En línea' : 'Offline'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Área de mensajes
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                controller: _chatScrollController,
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  final message = _chatMessages[index];
                  return _buildChatMessage(message);
                },
              ),
            ),
          ),
          
          // Input del chat
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                // Vista previa de imagen seleccionada
                if (_selectedImage != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.image,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedImage!.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: _removeSelectedImage,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Input row
                Row(
                  children: [
                    // Botón para adjuntar imagen
                    IconButton(
                      icon: Icon(
                        Icons.attach_file,
                        color: _selectedImage != null 
                            ? const Color(0xFF004B93) 
                            : Colors.grey[600],
                      ),
                      onPressed: _selectImage,
                      tooltip: 'Adjuntar imagen',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                    controller: _chatController,
                    enabled: !_isChatSending,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: 'Pregunta sobre el análisis...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFF004B93)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: IconButton(
                        icon: _isChatSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF004B93),
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Color(0xFF004B93),
                              ),
                        onPressed: _isChatSending ? null : _sendMessage,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: 1,
                  ),
                ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;
    final messageText = message['message'] as String;
    final timestamp = message['timestamp'] as DateTime;
    final isLoading = message['isLoading'] as bool? ?? false;
    final hasImage = message['hasImage'] as bool? ?? false;
    final imageName = message['imageName'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF004B93),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF004B93) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: isLoading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.grey[600]!,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              messageText,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasImage && imageName != null) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isUser 
                                      ? Colors.white.withOpacity(0.2) 
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      size: 16,
                                      color: isUser ? Colors.white : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      imageName,
                                      style: TextStyle(
                                        color: isUser ? Colors.white : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            Text(
                              messageText,
                              style: TextStyle(
                                color: isUser ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.grey,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _selectImage() {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.jpg,.jpeg,.png,.gif,.webp';
    
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        _selectedImage = files[0];
        _convertImageToBase64();
      }
    });
    
    uploadInput.click();
  }

  void _convertImageToBase64() {
    if (_selectedImage == null) return;
    
    final reader = html.FileReader();
    reader.onLoadEnd.listen((e) {
      final result = reader.result as String;
      setState(() {
        _selectedImageBase64 = result.split(',')[1]; // Remover el prefijo data:image/...;base64,
      });
    });
    reader.readAsDataUrl(_selectedImage!);
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBase64 = null;
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  void _sendMessage() {
    final messageText = _chatController.text.trim();
    if (messageText.isEmpty || _isChatSending) return;

    // Si no hay instancia de chat, usar respuesta de fallback
    if (_chatInstanceId == null) {
      _sendOfflineMessage(messageText);
      return;
    }

    setState(() {
      _isChatSending = true;
      
      // Agregar mensaje del usuario
      _chatMessages.add({
        'isUser': true,
        'message': messageText,
        'timestamp': DateTime.now(),
        'hasImage': _selectedImageBase64 != null,
        'imageName': _selectedImage?.name,
      });
      
      // Agregar indicador de carga para la respuesta de IA
      _chatMessages.add({
        'isUser': false,
        'message': 'Escribiendo...',
        'timestamp': DateTime.now(),
        'isLoading': true,
      });
    });

    _chatController.clear();
    _scrollToBottom();
    
    _sendMessageToAgent(messageText);
    
    // Limpiar imagen después de enviar
    Future.delayed(const Duration(milliseconds: 100), () {
      _removeSelectedImage();
    });
  }

  Future<void> _sendMessageToAgent(String message) async {
    try {
      final requestBody = [
        {
          'key': 'chatId',
          'value': _chatInstanceId!,
        },
        {
          'key': 'message',
          'value': message,
        },
        if (_selectedImageBase64 != null) ...[
          {
            'key': 'image',
            'value': _selectedImageBase64!,
          }
        ]
      ];
      
      print('Enviando mensaje con cuerpo: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('https://api.serenitystar.ai/api/v2/agent/NestleJuradoAsistente/execute'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': '10472b86-76cf-41d4-a27e-7fe76745d7db',
        },
        body: jsonEncode(requestBody),
      );

      print('Respuesta mensaje - Status: ${response.statusCode}');
      print('Respuesta mensaje - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        setState(() {
          // Remover mensaje de carga
          _chatMessages.removeWhere((msg) => msg['isLoading'] == true);
          
          // Agregar respuesta de la IA
          _chatMessages.add({
            'isUser': false,
            'message': data['content'] ?? 'Lo siento, no pude procesar tu mensaje.',
            'timestamp': DateTime.now(),
            'isLoading': false,
          });
          
          _isChatSending = false;
        });
      } else {
        print('Error HTTP mensaje ${response.statusCode}: ${response.body}');
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        // Remover mensaje de carga y mostrar error
        _chatMessages.removeWhere((msg) => msg['isLoading'] == true);
        _chatMessages.add({
          'isUser': false,
          'message': 'Error al enviar mensaje. Usando respuesta offline.',
          'timestamp': DateTime.now(),
          'isLoading': false,
        });
        _isChatSending = false;
      });
      
      // Agregar respuesta de fallback
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _chatMessages.add({
              'isUser': false,
              'message': _generatePlaceholderResponse(message),
              'timestamp': DateTime.now(),
            });
          });
        }
      });
      
      print('Error enviando mensaje: $e');
    }
    
    _scrollToBottom();
  }

  Future<void> _retryInitialization() async {
    try {
      // Reintentar con un mensaje aún más simple
      final simpleRequestBody = [
        {
          'key': 'message',
          'value': 'Hola',
        }
      ];
      
      print('Reintento con cuerpo simple: ${jsonEncode(simpleRequestBody)}');
      
      final response = await http.post(
        Uri.parse('https://api.serenitystar.ai/api/v2/agent/NestleCheckAsistente/execute'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': '10472b86-76cf-41d4-a27e-7fe76745d7db',
        },
        body: jsonEncode(simpleRequestBody),
      );

      print('Reintento - Status: ${response.statusCode}');
      print('Reintento - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _chatInstanceId = data['instanceId'];
        
        print('Instance ID obtenido en reintento: $_chatInstanceId');
        
        setState(() {
          _chatMessages.removeWhere((msg) => msg['isLoading'] == true);
          _chatMessages.add({
            'isUser': false,
            'message': data['content'] ?? '¡Hola! Soy tu asistente de análisis de Nestlé. ¿En qué puedo ayudarte con los resultados del análisis?',
            'timestamp': DateTime.now(),
            'isLoading': false,
          });
          _isChatInitializing = false;
        });
      } else {
        throw Exception('Error en reintento: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en reintento: $e');
      // Si falla el reintento, usar modo offline
      setState(() {
        _chatMessages.removeWhere((msg) => msg['isLoading'] == true);
        _chatMessages.add({
          'isUser': false,
          'message': 'No se pudo conectar con el asistente. Funcionando en modo offline.',
          'timestamp': DateTime.now(),
          'isLoading': false,
        });
        _isChatInitializing = false;
      });
    }
  }

  void _sendOfflineMessage(String messageText) {
    setState(() {
      // Agregar mensaje del usuario
      _chatMessages.add({
        'isUser': true,
        'message': messageText,
        'timestamp': DateTime.now(),
      });
    });

    _chatController.clear();
    _scrollToBottom();

    // Simular respuesta offline
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'isUser': false,
            'message': _generatePlaceholderResponse(messageText),
            'timestamp': DateTime.now(),
          });
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _generatePlaceholderResponse(String userMessage) {
    final responses = [
      'Gracias por tu pregunta. Basándome en el análisis del proyecto "${widget.projectName}", puedo ayudarte con más detalles específicos.',
      'He analizado tu consulta. Los resultados muestran un ${_analysisData?['complianceScore']}% de cumplimiento. ¿Te gustaría que profundice en algún aspecto específico?',
      'Según los datos del análisis, hay ${_analysisData?['invalidImages']} problemas identificados. ¿Quieres que te explique cómo resolverlos?',
      'Perfecto. Para el proyecto "${widget.projectName}", las principales recomendaciones están relacionadas con la posición del logo y la calibración de colores.',
      'Entiendo tu consulta. El análisis indica que ${_analysisData?['validImages']} de ${_analysisData?['totalImages']} imágenes cumplen con los estándares. ¿Necesitas más información sobre los problemas encontrados?',
    ];
    
    return responses[DateTime.now().millisecond % responses.length];
  }
}