import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import '../../core/auth/auth_service.dart';
import '../../core/services/serenity_api_service.dart';
import '../../database/cases_service.dart';
import '../../models/case_model.dart';

class NewArt extends StatefulWidget {
  const NewArt({super.key});

  @override
  State<NewArt> createState() => _NewArtState();
}

class _NewArtState extends State<NewArt> {
  final TextEditingController _productNameController = TextEditingController();
  final AuthService _authService = AuthService();
  final SerenityApiService _serenityApiService = SerenityApiService();
  final CasesService _casesService = CasesService();
  List<html.File> _selectedFiles = [];
  bool _isDragOver = false;
  bool _isUploading = false;
  String _uploadStatus = '';

  @override
  void dispose() {
    _productNameController.dispose();
    super.dispose();
  }

  void _handleFileSelection() {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.multiple = true;
    uploadInput.accept = '.jpg,.jpeg,.png,.pdf';
    
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null) {
        setState(() {
          _selectedFiles = files;
        });
      }
    });
    
    uploadInput.click();
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submitForAnalysis() async {
    if (_productNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el nombre del producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos un archivo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Obtener los datos del usuario actual
      final userData = await _authService.getCurrentUserData();
      if (userData == null) {
        throw Exception('No se pudo obtener la información del usuario');
      }

      final userId = userData['id']?.toString();
      if (userId == null) {
        throw Exception('ID de usuario no válido');
      }

      // Procesar cada archivo seleccionado secuencialmente
      for (int i = 0; i < _selectedFiles.length; i++) {
        final file = _selectedFiles[i];
        
        try {
          print('📤 Procesando archivo ${i + 1}/${_selectedFiles.length}: ${file.name}');
          
          // Actualizar estado en UI
          setState(() {
            _uploadStatus = 'Procesando ${i + 1}/${_selectedFiles.length}: ${file.name}';
          });
          
          // 1. Inicializar conversación
          print('   🔄 Iniciando conversación...');
          setState(() {
            _uploadStatus = 'Iniciando conversación ${i + 1}/${_selectedFiles.length}...';
          });
          
          final chatId = await _serenityApiService.initializeChat();
          print('   ✅ Conversación iniciada - Chat ID: $chatId');
          
          // Pequeña pausa entre operaciones
          await Future.delayed(const Duration(milliseconds: 1000));
          
          // 2. Subir archivo a Serenity API
          print('   🔄 Subiendo archivo...');
          setState(() {
            _uploadStatus = 'Subiendo archivo ${i + 1}/${_selectedFiles.length}... (Esto puede tomar unos minutos para archivos grandes)';
          });
          
          final uploadResponse = await _serenityApiService.uploadFile(file);
          print('   ✅ Archivo subido - ID: ${uploadResponse.id}');
          
          // Pequeña pausa entre operaciones
          await Future.delayed(const Duration(milliseconds: 1000));
          
          // 3. Ejecutar análisis con el chat ID y el ID del archivo
          print('   🔄 Ejecutando análisis...');
          setState(() {
            _uploadStatus = 'Analizando archivo ${i + 1}/${_selectedFiles.length}... (Procesando con IA, puede tomar varios minutos)';
          });
          
          final analysisResponse = await _serenityApiService.executeAnalysis(chatId, uploadResponse.id);
          print('   ✅ Análisis completado - Instance ID: ${analysisResponse.instanceId}');
          
          // Pequeña pausa entre operaciones
          await Future.delayed(const Duration(milliseconds: 1000));
          
          // 4. Guardar en la base de datos
          print('   🔄 Guardando en base de datos...');
          setState(() {
            _uploadStatus = 'Guardando resultados ${i + 1}/${_selectedFiles.length}...';
          });
          
          await _casesService.createCaseFromModel(
            CaseModel(
              name: _productNameController.text.trim(),
              serenityId: analysisResponse.instanceId,
              userId: userId,
              arteId: [uploadResponse.id], // Pasar como lista
            ),
          );
          print('   ✅ Caso guardado exitosamente');
          
          print('✅ Archivo procesado completamente: ${file.name}');
          
        } catch (fileError) {
          print('❌ Error procesando archivo ${file.name}: $fileError');
          
          // Mostrar error específico al usuario
          if (mounted) {
            String errorMessage = 'Error procesando ${file.name}';
            
            if (fileError.toString().contains('timeout') || fileError.toString().contains('Request timeout')) {
              errorMessage = 'Timeout procesando ${file.name}. El archivo puede ser muy grande o la conexión lenta. Intenta con un archivo más pequeño.';
            } else if (fileError.toString().contains('Network error')) {
              errorMessage = 'Error de conexión procesando ${file.name}. Verifica tu conexión a internet.';
            } else {
              errorMessage = 'Error procesando ${file.name}: ${fileError.toString()}';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 6),
              ),
            );
          }
          
          // Continuamos con el siguiente archivo en caso de error
          continue;
        }
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Archivos enviados para análisis exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navegar de vuelta al home
        context.go('/home');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar archivos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatus = '';
        });
      }
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
          'Nuevo Proyecto - Nestlé Validation Tool',
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
            // Título
            const Text(
              'Crear nuevo arte',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004B93),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Campo nombre del producto
            const Text(
              'Nombre del producto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _productNameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Arte (JPG, PNG o PDF)
            const Text(
              'Arte (JPG, PNG o PDF)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            // Área de drag & drop
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isDragOver ? const Color(0xFF004B93) : Colors.grey[300]!,
                    width: _isDragOver ? 2 : 1,
                  ),
                ),
                child: _selectedFiles.isEmpty
                    ? _buildDropZone()
                    : _buildFileList(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botones
            Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _submitForAnalysis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004B93),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isUploading
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              if (_uploadStatus.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Flexible(
                                  child: Text(
                                    _uploadStatus,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          )
                        : const Text(
                            'Enviar a análisis',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropZone() {
    return InkWell(
      onTap: _handleFileSelection,
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sube tus archivos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Formatos soportados: JPG, PNG, PDF',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.folder,
              size: 48,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Arrastra tus archivos aquí.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _handleFileSelection,
              child: const Text(
                'O haz clic para seleccionar',
                style: TextStyle(
                  color: Color(0xFF004B93),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Archivos seleccionados (${_selectedFiles.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _handleFileSelection,
                child: const Text(
                  'Agregar más',
                  style: TextStyle(color: Color(0xFF004B93)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _selectedFiles.length,
            itemBuilder: (context, index) {
              final file = _selectedFiles[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    _getFileIcon(file.name),
                    color: const Color(0xFF004B93),
                  ),
                  title: Text(file.name),
                  subtitle: Text(_formatFileSize(file.size)),
                  trailing: IconButton(
                    onPressed: () => _removeFile(index),
                    icon: const Icon(Icons.close, color: Colors.red),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}