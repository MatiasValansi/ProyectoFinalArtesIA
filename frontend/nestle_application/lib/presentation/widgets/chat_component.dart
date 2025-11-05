import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import '../../core/config/app_config.dart';
import '../../core/services/serenity_api_service.dart';
import '../../database/cases_service.dart';
import '../../database/storage_service.dart';
import '../../core/auth/auth_service.dart';

class ChatComponent extends StatefulWidget {
  final String projectName;
  final Map<String, dynamic>? analysisData;
  final String? caseSerenityId;
  final VoidCallback? onAnalysisUpdated; // Callback para notificar cambios

  const ChatComponent({
    super.key,
    required this.projectName,
    this.analysisData,
    this.caseSerenityId,
    this.onAnalysisUpdated, // Añadir el callback
  });

  @override
  State<ChatComponent> createState() => _ChatComponentState();
}

class _ChatComponentState extends State<ChatComponent> {
  final CasesService _casesService = CasesService();
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  List<Map<String, dynamic>> _chatMessages = [];
  bool _isChatSending = false;
  html.File? _selectedImage;
  String? _volatileKnowledgeId;
  bool _isUploadingFile = false;
  String _imageStatus = '';
  String? _imagePreviewUrl;

  /// Helper para hacer setState() seguro verificando si el widget está montado
  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

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
                            // Status icon
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
                            Spacer(),
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
    final imageUrl = message['imageUrl'] as String?;

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
                  constraints: const BoxConstraints(maxWidth: 280),
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
                            if (hasImage && imageUrl != null) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                width: double.infinity,
                                constraints: const BoxConstraints(maxHeight: 200),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isUser 
                                        ? Colors.white.withOpacity(0.3) 
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 80,
                                        color: isUser 
                                            ? Colors.white.withOpacity(0.2) 
                                            : Colors.grey[200],
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.broken_image,
                                                size: 32,
                                                color: isUser ? Colors.white : Colors.grey[600],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Error al cargar imagen',
                                                style: TextStyle(
                                                  color: isUser ? Colors.white : Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 80,
                                        color: isUser 
                                            ? Colors.white.withOpacity(0.2) 
                                            : Colors.grey[200],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / 
                                                  loadingProgress.expectedTotalBytes!
                                                : null,
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              isUser ? Colors.white : const Color(0xFF004B93),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              if (imageName != null) ...[
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
                                      Flexible(
                                        child: Text(
                                          imageName,
                                          style: TextStyle(
                                            color: isUser ? Colors.white : Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ] else if (hasImage && imageName != null) ...[
                              // Fallback si no hay URL pero sí imagen
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
                                    Flexible(
                                      child: Text(
                                        imageName,
                                        style: TextStyle(
                                          color: isUser ? Colors.white : Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (messageText.trim().isNotEmpty) ...[
                              Text(
                                messageText,
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ],
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
    
    setState(() {
      _isUploadingFile = true;
      _imageStatus = 'Iniciando...';
    });

    String? supabaseImageUrl;

    try {
      final serenityService = SerenityApiService();
      
      // Crear preview URL para la imagen
      final reader = html.FileReader();
      reader.readAsDataUrl(_selectedImage!);
      await reader.onLoad.first;
      
      setState(() {
        _imagePreviewUrl = reader.result as String?;
      });

      // 1. Obtener información del usuario actual
      final userData = await _authService.getCurrentUserData();
      final userId = userData?['id']?.toString() ?? 'unknown';

      // 2. Subir imagen a Supabase Storage primero
      _safeSetState(() {
        _imageStatus = 'Guardando imagen en servidor...';
      });

      supabaseImageUrl = await _storageService.uploadImageFromWeb(
        _selectedImage!,
        customPath: 'chat/${userId}', // Organizar en carpeta chat por usuario
        onProgress: (status) {
          if (mounted) {
            setState(() {
              _imageStatus = status;
            });
          }
        },
      );
      
      // 3. Subir imagen como volatile knowledge para análisis IA
      _safeSetState(() {
        _imageStatus = 'Preparando para análisis IA...';
      });
      
      _volatileKnowledgeId = await serenityService.uploadImage(_selectedImage!);
      
      // 4. Guardar inmediatamente el ID en la base de datos con URL de Supabase
      if (_volatileKnowledgeId != null) {
        await _addImageToDatabase(_volatileKnowledgeId!, supabaseImageUrl);
      }
      
      _safeSetState(() {
        _isUploadingFile = false;
        _imageStatus = 'Imagen guardada y lista para análisis';
      });
      
    } catch (e) {
      // Limpiar imagen de Supabase si se subió pero falló después
      if (supabaseImageUrl != null) {
        try {
          final fileName = supabaseImageUrl.split('/').last;
          final userData = await _authService.getCurrentUserData();
          final userId = userData?['id']?.toString() ?? 'unknown';
          await _storageService.deleteImage('chat/${userId}/$fileName');
        } catch (deleteError) {
          print('Error al eliminar imagen de Supabase: $deleteError');
        }
      }

      _safeSetState(() {
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

  /// Agregar imagen a la base de datos inmediatamente después del upload
  Future<void> _addImageToDatabase(String volatileKnowledgeId, [String? supabaseImageUrl]) async {
    try {
      // Verificar que tenemos serenity_id del caso
      if (widget.caseSerenityId == null || widget.caseSerenityId!.isEmpty) {
        return;
      }
      
      // Obtener casos por serenity_id
      final cases = await _casesService.getCasesBySerenityId(widget.caseSerenityId!);
      
      if (cases.isEmpty) {
        return;
      }
      
      final caseId = cases.first['id'];
      final currentArteId = cases.first['arte_id'] as List<dynamic>? ?? [];
      final currentImageUrls = cases.first['image_urls'] as List<dynamic>? ?? [];
      
      
      // Solo agregar si no está ya en el array (evitar duplicados)
      if (!currentArteId.contains(volatileKnowledgeId)) {
        final newArteId = List<String>.from(currentArteId)..add(volatileKnowledgeId);
        final newImageUrls = List<String>.from(currentImageUrls);
        
        // Agregar la URL de Supabase al array si se proporciona
        if (supabaseImageUrl != null && !newImageUrls.contains(supabaseImageUrl)) {
          newImageUrls.add(supabaseImageUrl);
        }
        await _casesService.client.from('cases').update({
          'arte_id': newArteId,
          'image_urls': newImageUrls,
        }).eq('id', caseId);
      }
      
    } catch (e) {
      // Error silencioso para mejor UX
    }
  }

  /// Remover imagen de la base de datos cuando se elimina del chat
  Future<void> _removeImageFromDatabase(String volatileKnowledgeId) async {
    try {
      // Verificar que tenemos serenity_id del caso
      if (widget.caseSerenityId == null || widget.caseSerenityId!.isEmpty) {
        return;
      }
      
      // Obtener casos por serenity_id
      final cases = await _casesService.getCasesBySerenityId(widget.caseSerenityId!);
      
      if (cases.isEmpty) {
        return;
      }
      
      final caseId = cases.first['id'];
      final currentArteId = cases.first['arte_id'] as List<dynamic>? ?? [];
      final currentImageUrls = cases.first['image_urls'] as List<dynamic>? ?? [];
      
      // Remover el ID del array si existe
      if (currentArteId.contains(volatileKnowledgeId)) {
        final arteIndex = currentArteId.indexOf(volatileKnowledgeId);
        final newArteId = List<String>.from(currentArteId)..remove(volatileKnowledgeId);
        final newImageUrls = List<String>.from(currentImageUrls);
        
        // Si hay la misma cantidad de URLs que de arte_ids, remover la URL correspondiente por índice
        if (arteIndex < newImageUrls.length && arteIndex >= 0) {
          newImageUrls.removeAt(arteIndex);
        }
        
        
        await _casesService.client.from('cases').update({
          'arte_id': newArteId,
          'image_urls': newImageUrls,
        }).eq('id', caseId);
      }
      
    } catch (e) {
      // Error silencioso para mejor UX
    }
  }

  void _removeSelectedImage() async {
    // Si hay un volatile knowledge ID, removerlo de la base de datos primero
    if (_volatileKnowledgeId != null) {
      await _removeImageFromDatabase(_volatileKnowledgeId!);
    }
    
    setState(() {
      _selectedImage = null;
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
        'hasImage': _selectedImage != null,
        'imageName': _selectedImage?.name,
        'imageUrl': _imagePreviewUrl, // Guardar la URL de la imagen
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
    
    // Guardar el volatile knowledge ID antes de limpiar la UI
    final volatileKnowledgeIdToSend = _volatileKnowledgeId;
    
    // Limpiar la imagen inmediatamente de la UI (mejor UX)
    if (_volatileKnowledgeId != null || _selectedImage != null) {
      setState(() {
        _volatileKnowledgeId = null;
        _selectedImage = null;
        _imageStatus = '';
        _imagePreviewUrl = null;
      });
    }
    
    _sendMessageToAgent(messageText, volatileKnowledgeIdToSend);
  }

  Future<void> _sendMessageToAgent(String message, String? volatileKnowledgeIdToSend) async {
    try {
      // Si no hay serenity_id del case, mostrar error
      if (widget.caseSerenityId == null || widget.caseSerenityId!.isEmpty) {
        _safeSetState(() {
          _chatMessages.removeWhere((msg) => msg['isLoading'] == true);
          _chatMessages.add({
            'isUser': false,
            'message': 'Error: No se pudo identificar el caso para el chat. Verifica que el caso tenga un ID de Serenity válido.',
            'timestamp': DateTime.now(),
            'isLoading': false,
          });
          _isChatSending = false;
        });
        if (mounted) _scrollToBottom();
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
        if (volatileKnowledgeIdToSend != null) ...[
          {
            'key': 'volatileKnowledgeIds',
            'value': [volatileKnowledgeIdToSend],
          }
        ]
      ];
      
      final response = await http.post(
        Uri.parse(AppConfig.nestleCheckAgentUrl),
        headers: AppConfig.apiHeaders,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Primero mostrar la respuesta al usuario
        _safeSetState(() {
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
        
        // Guardar solo los resultados del análisis (problemas, recomendaciones, score)
        await _saveAnalysisResults(data);
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      String errorMessage = 'Error de conexión: No se pudo enviar el mensaje.';
      
      if (e.toString().contains('SocketException') || e.toString().contains('Network')) {
        errorMessage = 'Error de red: Verifica tu conexión a internet e intenta nuevamente.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Error en la respuesta del servidor. Intenta nuevamente.';
      }
      
      _safeSetState(() {
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
      bool hasAnalysis = data['actionResults'] != null && data['actionResults']['conclusion'] != null;
      
      if (!hasAnalysis) {
        return;
      }

      Map<String, dynamic>? analisis;
      
      if (hasAnalysis) {
        final conclusion = data['actionResults']['conclusion'];
        
        if (conclusion['jsonContent'] != null) {
          analisis = conclusion['jsonContent'];
        } else {
          // Intentar parsear desde content si no hay jsonContent
          try {
            analisis = jsonDecode(conclusion['content']);
          } catch (e) {
            analisis = null; // No hay análisis válido
          }
        }
      }
      
      // Verificar que tenemos serenity_id del caso
      if (widget.caseSerenityId == null || widget.caseSerenityId!.isEmpty) {
        return;
      }
      
      // Obtener casos por serenity_id
      final cases = await _casesService.getCasesBySerenityId(widget.caseSerenityId!);
      
      if (cases.isEmpty) {
        return;
      }
      
      final caseId = cases.first['id'];
      
      // Preparar los datos para actualizar
      final updateData = <String, dynamic>{};
      
      // Solo procesar análisis si existe
      if (analisis != null) {
        // Guardar problemas (convertir de objeto a array de problemas)
        if (analisis['problemas'] != null) {
          final problemsMap = analisis['problemas'] as Map<String, dynamic>;
          final problemsList = <Map<String, dynamic>>[];
          
          problemsMap.forEach((key, value) {
            if (value is Map<String, dynamic> && value.containsKey('titulo') && value.containsKey('detalle')) {
              problemsList.add({
                'id': key,
                'titulo': value['titulo'],
                'detalle': value['detalle'],
              });
            }
          });
          
          updateData['problems'] = problemsList;
        }
        
        // Guardar recomendaciones (convertir a array de strings simples)
        if (analisis['recomendaciones'] != null) {
          final recommendationsList = <String>[];
          
          if (analisis['recomendaciones'] is Map) {
            // Convertir las recomendaciones de objeto a array de strings
            final recomendaciones = analisis['recomendaciones'] as Map<String, dynamic>;
            recomendaciones.values.forEach((value) {
              recommendationsList.add(value.toString());
            });
          } else if (analisis['recomendaciones'] is List) {
            // Si ya es una lista, extraer solo el texto
            final recomendaciones = analisis['recomendaciones'] as List;
            for (final recommendation in recomendaciones) {
              recommendationsList.add(recommendation.toString());
            }
          } else if (analisis['recomendaciones'] is String) {
            // Si es un string, agregarlo directamente
            recommendationsList.add(analisis['recomendaciones'].toString());
          }
          
          updateData['recommendations'] = recommendationsList;
        }
        
        // Guardar score (como número)
        if (analisis['puntuacion'] != null) {
          double? score;
          if (analisis['puntuacion'] is num) {
            score = analisis['puntuacion'].toDouble();
          } else if (analisis['puntuacion'] is String) {
            score = double.tryParse(analisis['puntuacion']);
          }
          if (score != null) {
            updateData['score'] = score;
          }
        }
      }
      
      // Actualizar el caso solo si hay datos para actualizar
      if (updateData.isNotEmpty) {
        await _casesService.client.from('cases').update(updateData).eq('id', caseId);
        // Notificar al componente padre que los datos han sido actualizados
        if (widget.onAnalysisUpdated != null && mounted) {
          // Usar Future.microtask para asegurar que se ejecute después del frame actual
          Future.microtask(() {
            if (mounted && widget.onAnalysisUpdated != null) {
              widget.onAnalysisUpdated!();
            }
          });
        }
      }
      
    } catch (e) {
      // Error silencioso para mejor UX
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