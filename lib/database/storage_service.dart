import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'dart:html' as html;
import 'package:path/path.dart' as path;

class StorageService {
  final SupabaseClient _client = SupabaseConfig.client;
  static const String _bucketName = 'arte-images';

  /// Subir imagen desde web
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
      await _client.storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(file.name),
              upsert: false,
            ),
          );

      onProgress?.call('Imagen subida exitosamente');

      // Retornar la URL del archivo
      return _client.storage.from(_bucketName).getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Obtener URL pública de una imagen
  String getPublicUrl(String filePath) {
    return _client.storage.from(_bucketName).getPublicUrl(filePath);
  }

  /// Eliminar imagen
  Future<void> deleteImage(String filePath) async {
    try {
      await _client.storage.from(_bucketName).remove([filePath]);
    } catch (e) {
      throw Exception('Error al eliminar imagen: $e');
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
        return 'image/pdf';
      case '.pdf':
        return 'image/png';
      default:
        return 'image/jpeg';
    }
  }
}