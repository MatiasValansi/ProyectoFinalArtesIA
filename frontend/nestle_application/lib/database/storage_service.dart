import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'dart:html' as html;
import 'package:path/path.dart' as path;

class StorageService {
  final SupabaseClient _client = SupabaseConfig.client;
  
  // Nombre del bucket que debes crear en Supabase
  static const String _bucketName = 'arte-images';

  /// Subir imagen desde web (html.File)
  Future<String> uploadImageFromWeb(
    html.File file, {
    String? customPath,
    Function(String)? onProgress,
  }) async {
    try {
      onProgress?.call('Preparando imagen...');
      
      // Generar nombre único para el archivo
      final String fileName = _generateUniqueFileName(file.name);
      final String filePath = customPath != null 
          ? '$customPath/$fileName' 
          : 'uploads/$fileName';

      onProgress?.call('Subiendo imagen...');

      // Leer el archivo como bytes
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      
      final Uint8List bytes = reader.result as Uint8List;

      // Subir archivo a Supabase Storage
      await _client.storage.from(_bucketName).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: _getContentType(file.name),
          upsert: false, // No sobrescribir archivos existentes
        ),
      );

      onProgress?.call('Imagen subida exitosamente');

      // Retornar la URL pública del archivo
      return _client.storage.from(_bucketName).getPublicUrl(filePath);
      
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Subir imagen desde bytes (para móvil con image_picker)
  Future<String> uploadImageFromBytes(
    Uint8List bytes,
    String fileName, {
    String? customPath,
    Function(String)? onProgress,
  }) async {
    try {
      onProgress?.call('Preparando imagen...');
      
      final String uniqueFileName = _generateUniqueFileName(fileName);
      final String filePath = customPath != null 
          ? '$customPath/$uniqueFileName' 
          : 'uploads/$uniqueFileName';

      onProgress?.call('Subiendo imagen...');

      await _client.storage.from(_bucketName).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: _getContentType(fileName),
          upsert: false,
        ),
      );

      onProgress?.call('Imagen subida exitosamente');

      return _client.storage.from(_bucketName).getPublicUrl(filePath);
      
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Obtener URL pública de una imagen
  String getPublicUrl(String filePath) {
    return _client.storage.from(_bucketName).getPublicUrl(filePath);
  }

  /// Obtener URL firmada (para buckets privados)
  Future<String> getSignedUrl(String filePath, {int expiresIn = 3600}) async {
    try {
      return await _client.storage
          .from(_bucketName)
          .createSignedUrl(filePath, expiresIn);
    } catch (e) {
      throw Exception('Error al obtener URL firmada: $e');
    }
  }

  /// Eliminar imagen
  Future<void> deleteImage(String filePath) async {
    try {
      await _client.storage.from(_bucketName).remove([filePath]);
    } catch (e) {
      throw Exception('Error al eliminar imagen: $e');
    }
  }

  /// Listar archivos en un directorio
  Future<List<FileObject>> listFiles({String? prefix}) async {
    try {
      return await _client.storage
          .from(_bucketName)
          .list(path: prefix);
    } catch (e) {
      throw Exception('Error al listar archivos: $e');
    }
  }

  /// Crear el bucket si no existe (solo para desarrollo)
  Future<void> createBucketIfNotExists({bool isPublic = false}) async {
    try {
      await _client.storage.createBucket(
        _bucketName,
        BucketOptions(
          public: isPublic,
          allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
          fileSizeLimit: '10MB',
        ),
      );
    } catch (e) {
      // El bucket ya existe o hay otro error
      print('Info: El bucket puede que ya exista: $e');
    }
  }

  /// Generar nombre único para el archivo
  String _generateUniqueFileName(String originalName) {
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String extension = path.extension(originalName).toLowerCase();
    final String nameWithoutExt = path.basenameWithoutExtension(originalName);
    
    // Limpiar el nombre del archivo
    final String cleanName = nameWithoutExt
        .replaceAll(RegExp(r'[^\w\-_\.]'), '_')
        .toLowerCase();
    
    return '${cleanName}_$timestamp$extension';
  }

  /// Obtener content type basado en la extensión
  String _getContentType(String fileName) {
    final String extension = path.extension(fileName).toLowerCase();
    
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Validar tamaño de archivo
  bool isValidFileSize(int sizeInBytes, {int maxSizeMB = 10}) {
    final int maxSizeBytes = maxSizeMB * 1024 * 1024;
    return sizeInBytes <= maxSizeBytes;
  }

  /// Validar tipo de archivo
  bool isValidImageType(String fileName) {
    final String extension = path.extension(fileName).toLowerCase();
    final List<String> allowedTypes = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    return allowedTypes.contains(extension);
  }
}