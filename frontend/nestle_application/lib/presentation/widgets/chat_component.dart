import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import '../../core/config/app_config.dart';
import '../../core/services/serenity_api_service.dart';
import '../../database/cases_service.dart';

class ChatComponent extends StatefulWidget {
  final String projectName;
  final Map<String, dynamic>? analysisData;
  final String? caseSerenityId;

  const ChatComponent({
    super.key,
    required this.projectName,
    this.analysisData,
    this.caseSerenityId,
  });

  @override
  State<ChatComponent> createState() => _ChatComponentState();
}

class _ChatComponentState extends State<ChatComponent> {
  final CasesService _casesService = CasesService();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  List<Map<String, dynamic>> _chatMessages = [];
  bool _isChatSending = false;
  html.File? _selectedImage;
  String? _selectedImageBase64;
  String? _volatileKnowledgeId;
  bool _isUploadingFile = false;
  String _imageStatus = '';
  String? _imagePreviewUrl;

  @override
  void initState() {
    super.initState();
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
        'message': '¡Hola! Soy tu asistente de análisis de arte. Puedes preguntarme cualquier cosa sobre el análisis realizado en este proyecto.',
        'timestamp': DateTime.now(),
        'isLoading': false,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
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
                    child: Column(
                      children: [
                        // Preview de la imagen
                        if (_imagePreviewUrl != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            height: 80,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _imagePreviewUrl!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                        // Info de la imagen
                        Row(
                          children: [
                            if (_isUploadingFile)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF004B93),
                                  ),
                                ),
                              )
                            else if (_volatileKnowledgeId != null)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              )
                            else if (_selectedImage != null && _volatileKnowledgeId == null)
                              Icon(
                                Icons.pending,
                                color: Colors.orange[600],
                                size: 20,
                              )
                            else
                              Icon(
                                Icons.attach_file,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedImage!.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_isUploadingFile)
                                    Text(
                                      _imageStatus.isEmpty ? 'Subiendo archivo...' : _imageStatus,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    )
                                  else if (_volatileKnowledgeId != null)
                                    Text(
                                      'Archivo listo para analizar',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    )
                                  else
                                    Text(
                                      'Toque para subir archivo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (!_isUploadingFile)
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
                        color: (_selectedImage != null && !_isUploadingFile) 
                            ? const Color(0xFF004B93) 
                            : Colors.grey[600],
                      ),
                      onPressed: _isUploadingFile ? null : _selectImage,
                      tooltip: _isUploadingFile 
                              ? 'Subiendo archivo...'
                              : 'Adjuntar archivo',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        enabled: !_isChatSending && !_isUploadingFile,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: _isUploadingFile
                                  ? 'Procesando imagen...'
                                  : 'Pregunta sobre el análisis...',
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
                            icon: (_isChatSending || _isUploadingFile)
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
                            onPressed: (_isChatSending || _isUploadingFile) ? null : _sendMessage,
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
                            Flexible(
                              child: Text(
                                messageText,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
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
        _uploadFileToVolatileKnowledge();
      }
    });
    
    uploadInput.click();
  }

  Future<void> _uploadFileToVolatileKnowledge() async {
    if (_selectedImage == null) return;
    
    print('=== INICIANDO UPLOAD ===');
    print('Archivo: ${_selectedImage!.name}, Tamaño: ${_selectedImage!.size} bytes');
    
    setState(() {
      _isUploadingFile = true;
      _imageStatus = 'Iniciando...';
    });

    try {
      final serenityService = SerenityApiService();
      
      // Crear preview URL para la imagen
      final reader = html.FileReader();
      reader.readAsDataUrl(_selectedImage!);
      await reader.onLoad.first;
      
      setState(() {
        _imagePreviewUrl = reader.result as String?;
      });
      
      print('Preview creado correctamente');
      
      // Subir imagen como volatile knowledge
      print('Iniciando upload a volatile knowledge...');
      _volatileKnowledgeId = await serenityService.uploadImageToVolatileKnowledge(
        _selectedImage!,
        onStatusUpdate: (status) {
          print('Status update: $status');
          // Actualizar el estado mostrado al usuario
          if (mounted) {
            setState(() {
              _imageStatus = status;
            });
          }
        },
      );
      
      print('Upload completado. ID: $_volatileKnowledgeId');
      
      setState(() {
        _isUploadingFile = false;
        _imageStatus = 'Imagen lista para análisis';
      });
      
    } catch (e) {
      print('=== ERROR EN UPLOAD ===');
      print('Error: $e');
      print('Tipo de error: ${e.runtimeType}');
      
      setState(() {
        _isUploadingFile = false;
        _imageStatus = 'Error al subir imagen';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBase64 = null;
      _volatileKnowledgeId = null;
      _imageStatus = '';
      _imagePreviewUrl = null;
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
    if (messageText.isEmpty || _isChatSending || _isUploadingFile) return;

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

    Future.delayed(const Duration(milliseconds: 100), () {
      _removeSelectedImage();
    });
  }

  Future<void> _sendMessageToAgent(String message) async {
    try {
      // Si no hay serenity_id del case, mostrar error
      if (widget.caseSerenityId == null || widget.caseSerenityId!.isEmpty) {
        setState(() {
          _chatMessages.removeWhere((msg) => msg['isLoading'] == true);
          _chatMessages.add({
            'isUser': false,
            'message': 'Error: No se pudo identificar el caso para el chat. Verifica que el caso tenga un ID de Serenity válido.',
            'timestamp': DateTime.now(),
            'isLoading': false,
          });
          _isChatSending = false;
        });
        _scrollToBottom();
        return;
      }

      final requestBody = [
        {
          'key': 'chatId',
          'value': widget.caseSerenityId!,
        },
        {
          'key': 'message',
          'value': message,
        },
        if (_volatileKnowledgeId != null) ...[
          {
            'key': 'volatileKnowledgeIds',
            'value': [_volatileKnowledgeId!],
          }
        ]
      ];
      
      print('Enviando request a agente:');
      print('URL: ${AppConfig.nestleCheckAgentUrl}');
      print('Body: ${jsonEncode(requestBody)}');
      print('Volatile Knowledge ID: $_volatileKnowledgeId');
      
      final response = await http.post(
        Uri.parse(AppConfig.nestleCheckAgentUrl),
        headers: AppConfig.apiHeaders,
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 120)); // Timeout de 2 minutos para análisis

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Primero mostrar la respuesta al usuario
        setState(() {
          // Remover mensaje de carga
          _chatMessages.removeWhere((msg) => msg['isLoading'] == true);
          // Agregar respuesta de la IA
          _chatMessages.add({
            'isUser': false,
            'message': data['content'],
            'timestamp': DateTime.now(),
            'isLoading': false,
          });
          _isChatSending = false;
        });

        // Luego intentar guardar en la base de datos (sin bloquear el chat)
        _saveAnalysisResults(data);
      } else {
        print('Error HTTP mensaje ${response.statusCode}: ${response.body}');
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en _sendMessageToAgent: $e');
      String errorMessage = 'Error de conexión: No se pudo enviar el mensaje.';
      
      if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
        errorMessage = 'La solicitud tardó mucho tiempo. El análisis de imágenes puede tomar varios minutos. Intenta nuevamente.';
      } else if (e.toString().contains('SocketException') || e.toString().contains('Network')) {
        errorMessage = 'Error de red: Verifica tu conexión a internet e intenta nuevamente.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Error en la respuesta del servidor. Intenta nuevamente.';
      }
      
      setState(() {
        // Remover mensaje de carga y mostrar error
        _chatMessages.removeWhere((msg) => msg['isLoading'] == true);
        _chatMessages.add({
          'isUser': false,
          'message': errorMessage,
          'timestamp': DateTime.now(),
          'isLoading': false,
        });
        _isChatSending = false;
      });  
    }
    
    _scrollToBottom();
  }



  /// Guardar resultados del análisis en la base de datos (método asíncrono separado)
  Future<void> _saveAnalysisResults(Map<String, dynamic> data) async {
    try {
      // Verificar si hay conclusión en la respuesta
      if (data['actionResults'] == null || data['actionResults']['conclusion'] == null) {
        print('No hay conclusión en la respuesta para guardar');
        return;
      }

      final conclusion = data['actionResults']['conclusion'];
      Map<String, dynamic> analisis;
      
      if (conclusion['jsonContent'] != null) {
        analisis = conclusion['jsonContent'];
      } else {
        analisis = jsonDecode(conclusion['content']);
      }
      
      // Verificar que tenemos serenity_id del caso
      if (widget.caseSerenityId == null || widget.caseSerenityId!.isEmpty) {
        print('No hay serenity_id del caso para guardar análisis');
        return;
      }
      
      print('Intentando guardar análisis para serenity_id: ${widget.caseSerenityId}');
      
      // Obtener casos por serenity_id
      final cases = await _casesService.getCasesBySerenityId(widget.caseSerenityId!);
      
      if (cases.isEmpty) {
        print('No se encontraron casos con serenity_id: ${widget.caseSerenityId}');
        return;
      }
      
      if (cases.length > 1) {
        print('ADVERTENCIA: Se encontraron ${cases.length} casos con el mismo serenity_id');
      }
      
      final caseId = cases.first['id'];
      print('Guardando análisis en caso ID: $caseId');
      
      // Actualizar el caso con los resultados del análisis
      await _casesService.client.from('cases').update({
        'problems': analisis['problemas'],
        'recommendations': analisis['recomendaciones'],
        'score': analisis['puntuacion'],
      }).eq('id', caseId);
      
      print('Análisis guardado correctamente en el caso');
      
    } catch (e) {
      print('Error al guardar análisis en base de datos: $e');
      // No mostrar error al usuario ya que el chat funcionó correctamente
    }
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
}