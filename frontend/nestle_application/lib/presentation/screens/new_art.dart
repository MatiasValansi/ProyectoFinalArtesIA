
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../../core/auth/auth_service.dart';
import '../../core/services/serenity_api_service.dart';
import '../../database/cases_service.dart';
import '../../models/case_model.dart';


class AnalisisResultado {
  final Map<String, dynamic> problemas;
  final Map<String, dynamic> recomendaciones;
  final int puntuacion;

  AnalisisResultado({
    required this.problemas,
    required this.recomendaciones,
    required this.puntuacion,
  });
}

AnalisisResultado extraerAnalisis(String respuestaAgente) {
  final Map<String, dynamic> data = json.decode(respuestaAgente);
  final conclusion = data['actionResults']['conclusion'];
  Map<String, dynamic> analisis;
  if (conclusion['jsonContent'] != null) {
    analisis = conclusion['jsonContent'];
  } else {
    analisis = json.decode(conclusion['content']);
  }
  return AnalisisResultado(
    problemas: Map<String, dynamic>.from(analisis['problemas']),
    recomendaciones: Map<String, dynamic>.from(analisis['recomendaciones']),
    puntuacion: analisis['puntuacion'],
  );
}

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
    uploadInput.multiple = false; // Solo un archivo
    uploadInput.accept = '.jpg,.jpeg,.png';
    
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        setState(() {
          _selectedFiles = [files[0]]; // Solo tomar el primer archivo
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
          content: Text('Por favor selecciona un archivo'),
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

      // Procesar la imagen seleccionada
      final file = _selectedFiles.first;
      
      try {
        setState(() {
          _uploadStatus = 'Procesando imagen: ${file.name}';
        });
        
        final chatId = await _serenityApiService.initializeChat();
        
        // Subir imagen como volatile knowledge
        final volatileKnowledgeId = await _serenityApiService.uploadImageToVolatileKnowledge(
          file,
          onStatusUpdate: (status) {
            if (mounted) {
              setState(() {
                _uploadStatus = status;
              });
            }
          },
        );
          
        // Una vez que el volatile knowledge esté listo, ejecutar el análisis
        setState(() {
          _uploadStatus = 'Ejecutando análisis...';
        });
        
        final analysisResponse = await _serenityApiService.executeAnalysis(chatId, volatileKnowledgeId);

        await _casesService.createCaseFromModel(
          CaseModel(
            name: _productNameController.text.trim(),
            serenityId: analysisResponse.instanceId,
            userId: userId,
            arteId: [volatileKnowledgeId], // Usar el ID del volatile knowledge
          ),
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagen enviada para análisis exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navegar de vuelta al home
          context.go('/home');
        }
        
      } catch (fileError) {
        print('ERROR: no se pudo procesar la imagen ${file.name}: $fileError');
        
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
              'Crear nuevo proyecto',
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
              'Sube tu archivos',
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
              'Arrastra tu archivo aquí.',
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
    if (_selectedFiles.isEmpty) {
      return const Center(
        child: Text(
          'No hay archivos seleccionados',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    final file = _selectedFiles.first;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Imagen seleccionada',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _handleFileSelection,
                child: const Text(
                  'Cambiar',
                  style: TextStyle(color: Color(0xFF004B93)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                color: Colors.grey[50],
              ),
              child: Column(
                children: [
                  // Preview de la imagen
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FutureBuilder<String>(
                          future: _getImagePreview(file),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.network(
                                snapshot.data!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                              );
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  // Info del archivo
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.image,
                          color: const Color(0xFF004B93),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _formatFileSize(file.size),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeFile(0),
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: 'Eliminar imagen',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<String> _getImagePreview(html.File file) async {
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;
    return reader.result as String;
  }



  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}