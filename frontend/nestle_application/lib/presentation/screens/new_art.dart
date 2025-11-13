import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../../core/auth/auth_service.dart';
import '../../core/services/serenity_api_service.dart';
import '../../database/cases_service.dart';
import '../../database/storage_service.dart';
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
  final StorageService _storageService = StorageService();
  List<html.File> _selectedFiles = [];
  bool _isDragOver = false;
  bool _isUploading = false;
  bool _isImageProcessing = false;
  String? _volatileKnowledgeId;

  @override
  void dispose() {
    _productNameController.dispose();
    super.dispose();
  }

  void _handleFileSelection() {
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.multiple = false;
    uploadInput.accept = '.jpg,.jpeg,.png';

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        
        // Verificar el tamaño del archivo (1MB = 1 * 1024 * 1024 bytes)
        const maxSize = 1 * 1024 * 1024; // 1MB
        if (file.size > maxSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'La imagen es muy grande (${_formatFileSize(file.size)}). El límite es de 1MB.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        setState(() {
          _selectedFiles = [file];
          // Resetear estados cuando se selecciona una nueva imagen
          _isImageProcessing = false;
          _volatileKnowledgeId = null;
        });
        // Procesar la imagen automáticamente cuando se selecciona
        _processImage();
      }
    });

    uploadInput.click();
  }

  Future<void> _processImage() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isImageProcessing = true;
    });

    try {
      final file = _selectedFiles.first;
      
      // Subir imagen para análisis IA
      final volatileKnowledgeId = await _serenityApiService.uploadImage(file);
      
      // Esperar hasta que la imagen esté completamente procesada
      await _serenityApiService.waitForVolatileKnowledgeReady(volatileKnowledgeId);
      
      setState(() {
        _volatileKnowledgeId = volatileKnowledgeId;
        _isImageProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen procesada y lista para análisis'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImageProcessing = false;
        _volatileKnowledgeId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      // Resetear estados cuando se elimina la imagen
      _isImageProcessing = false;
      _volatileKnowledgeId = null;
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

    if (_volatileKnowledgeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor espera a que la imagen se procese'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final userData = await _authService.getCurrentUserData();
      if (userData == null) {
        throw Exception('No se pudo obtener la información del usuario');
      }

      final userId = userData['id']?.toString();
      if (userId == null) {
        throw Exception('ID de usuario no válido');
      }
      final file = _selectedFiles.first;
      String? supabaseImageUrl;

      try {
        // Subir imagen a Supabase
        supabaseImageUrl = await _storageService.uploadImageFromWeb(
          file,
          customPath: 'cases/${userId}',
        );

        // Inicializar chat
        final chatId = await _serenityApiService.initializeChat();

        // Ejecutar el análisis con la imagen ya procesada
        final analysisResponse = await _serenityApiService.executeAnalysis(
          chatId,
          _volatileKnowledgeId!,
        );

        // Crear el caso en Supabase
        final createdCase = await _casesService.createCaseFromModel(
          CaseModel(
            name: _productNameController.text.trim(),
            serenityId: analysisResponse.instanceId,
            userId: userId,
            arteId: [_volatileKnowledgeId!],
            imageUrls: [supabaseImageUrl],
          ),
        );

        // Extraer y guardar los resultados del análisis
        await _extractAndSaveAnalysisResults(analysisResponse, createdCase.id!);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagen enviada para análisis exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/home');
        }
      } catch (fileError) {
        // Limpiar imagen de Supabase si se subió pero falló el análisis
        if (supabaseImageUrl != null) {
          try {
            final fileName = supabaseImageUrl.split('/').last;
            await _storageService.deleteImage('cases/${userId}/$fileName');
          } catch (deleteError) {
            // No hacer nada si falla
          }
        }

        // Mostrar error al usuario
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ocurrió un error al procesar la imagen. Intenta nuevamente.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 6),
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
        });
      }
    }
  }

  /// Extraer y guardar los resultados del análisis
  Future<void> _extractAndSaveAnalysisResults(
    dynamic analysisResponse,
    String caseId,
  ) async {
    try {
      // Ver si se hizo el analisis
      if (analysisResponse.actionResults == null ||
          analysisResponse.actionResults['conclusion'] == null) {
        return;
      }

      final conclusion = analysisResponse.actionResults['conclusion'];
      Map<String, dynamic> analisis;

      if (conclusion['jsonContent'] != null) {
        analisis = conclusion['jsonContent'];
      } else {
        try {
          analisis = jsonDecode(conclusion['content']);
        } catch (e) {
          throw ('Error al parsear JSON: $e');
        }
      }

      // Preparar los datos para actualizar
      final updateData = <String, dynamic>{};

      // Guardar problemas
      if (analisis['problemas'] != null) {
        final problemsMap = analisis['problemas'] as Map<String, dynamic>;
        final problemsList = <Map<String, dynamic>>[];

        problemsMap.forEach((key, value) {
          if (value is Map<String, dynamic> &&
              value.containsKey('titulo') &&
              value.containsKey('detalle')) {
            problemsList.add({
              'id': key,
              'titulo': value['titulo'],
              'detalle': value['detalle'],
            });
          }
        });

        updateData['problems'] = problemsList;
      }

      // Guardar recomendaciones
      if (analisis['recomendaciones'] != null) {
        final recommendationsList = <String>[];

        if (analisis['recomendaciones'] is Map) {
          // Convertir las recomendaciones a array
          final recomendaciones =
              analisis['recomendaciones'] as Map<String, dynamic>;
          recomendaciones.values.forEach((value) {
            recommendationsList.add(value.toString());
          });
        } else if (analisis['recomendaciones'] is List) {
          // Extraer texto si es una lista
          final recomendaciones = analisis['recomendaciones'] as List;
          for (final recommendation in recomendaciones) {
            recommendationsList.add(recommendation.toString());
          }
        } else if (analisis['recomendaciones'] is String) {
          // Agregar directamente si es un string
          recommendationsList.add(analisis['recomendaciones'].toString());
        }

        updateData['recommendations'] = recommendationsList;
      }

      // Guardar score
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

      // Actualizar el caso
      if (updateData.isNotEmpty) {
        await _casesService.client
            .from('cases')
            .update(updateData)
            .eq('id', caseId);
      }
    } catch (e) {
      throw ('ERROR: $e');
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        context.pushReplacement('/login');
      }
    } catch (e) {
      throw ('ERROR: $e');
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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

            // Arte
            const Text(
              'Arte (JPG, PNG o PDF)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Tamaño máximo: 1MB',
              style: TextStyle(
                fontSize: 12, 
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
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
                    color: _isDragOver
                        ? const Color(0xFF004B93)
                        : Colors.grey[300]!,
                    width: _isDragOver ? 2 : 1,
                  ),
                ),
                child: _selectedFiles.isEmpty
                    ? _buildDropZone()
                    : _buildFileList(),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isUploading || _isImageProcessing || _volatileKnowledgeId == null) 
                        ? null 
                        : _submitForAnalysis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004B93),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : _isImageProcessing
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Procesando imagen...',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              )
                            : Text(
                                _volatileKnowledgeId == null 
                                    ? 'Selecciona una imagen primero'
                                    : 'Enviar a análisis',
                                style: const TextStyle(fontSize: 16),
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
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Icon(Icons.folder, size: 48, color: Colors.orange[400]),
            const SizedBox(height: 16),
            Text(
              'Arrastra tu archivo aquí.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
          style: TextStyle(fontSize: 16, color: Colors.grey),
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
                  // Estado de procesamiento
                  if (_isImageProcessing || _volatileKnowledgeId != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        color: _isImageProcessing 
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isImageProcessing 
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isImageProcessing)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                              ),
                            )
                          else
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            _isImageProcessing 
                                ? 'Procesando'
                                : 'Imagen lista',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isImageProcessing 
                                  ? Colors.orange[800]
                                  : Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
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
