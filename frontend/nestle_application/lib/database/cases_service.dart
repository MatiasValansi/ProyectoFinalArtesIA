import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import '../models/case_model.dart';

class CasesService {
  final SupabaseClient client = SupabaseConfig.client;

  /// Crear caso
  Future<Map<String, dynamic>> createCase({
    required String name,
    required String serenityId,
    required String userId,
    required List<String> arteId,
    bool? approved,
    Map<String, dynamic>? problems,
    double? score,
    String? recommendations,
    List<String>? imageUrls,
  }) async {
    try {
      final response = await client.from('cases').insert({
        'name': name,
        'serenity_id': serenityId,
        'user_id': userId,
        'arte_id': arteId, // Ahora es una lista
        'active': true,
        'created_at': DateTime.now().toIso8601String(),
        if (approved != null) 'approved': approved,
        if (problems != null) 'problems': problems,
        if (score != null) 'score': score,
        if (recommendations != null) 'recommendations': recommendations,
        if (imageUrls != null) 'image_urls': imageUrls,
      }).select().single();

      return response;
    } catch (e) {
      throw Exception('Error al crear caso: $e');
    }
  }

  /// Obtener casos
  Future<List<Map<String, dynamic>>> getAllCases() async {
    try {
      final response = await client
          .from('cases')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener casos: $e');
    }
  }

  /// Obtener todos los casos con información del usuario para supervisores
  Future<List<Map<String, dynamic>>> getAllCasesWithUserInfo() async {
    try {
      final response = await client
          .from('cases')
          .select('''
            *,
            user_id!inner(
              id,
              email,
              rol
            )
          ''')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response).map((caseData) {
        final userData = caseData['user_id'];
        if (userData == null || userData is! Map) {
          caseData['user_id'] = null;
        } else {
          // Asegurar que todos los campos requeridos existan
          caseData['user_id'] = {
            'id': userData['id']?.toString() ?? 'unknown',
            'email': userData['email']?.toString() ?? 'usuario@desconocido.com',
            'rol': userData['rol']?.toString() ?? 'user',
          };
        }
        return caseData;
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener casos con información de usuario: $e');
    }
  }

  /// Obtener casos por usuario
  Future<List<Map<String, dynamic>>> getCasesByUser(String userId) async {
    try {
      final response = await client
          .from('cases')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener casos del usuario: $e');
    }
  }

  /// Obtener casos por serenity_id
  Future<List<Map<String, dynamic>>> getCasesBySerenityId(String serenityId) async {
    try {
      final response = await client
          .from('cases')
          .select()
          .eq('serenity_id', serenityId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener casos: $e');
    }
  }

  /// Obtener un caso por ID
  Future<Map<String, dynamic>?> getCaseById(String caseId) async {
    try {
      final response = await client
          .from('cases')
          .select()
          .eq('id', caseId)
          .single();
      return response;
    } catch (e) {
      throw Exception('Error al obtener caso por ID: $e');
    }
  }

  /// Actualizar estado de aprobación de un caso
  Future<void> updateCaseApprovalStatus(String caseId, bool approved) async {
    try {
      await client
          .from('cases')
          .update({'approved': approved})
          .eq('id', caseId);
    } catch (e) {
      throw Exception('Error al actualizar estado de aprobación del caso: $e');
    }
  }

  /// Crear un nuevo caso 
  Future<CaseModel> createCaseFromModel(CaseModel caseModel) async {
    try {
      final response = await client.from('cases').insert(caseModel.toJson()).select().single();
      return CaseModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear caso desde modelo: $e');
    }
  }

}