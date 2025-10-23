import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import '../models/case_model.dart';

class CasesService {
  final SupabaseClient client = SupabaseConfig.client;

  /// Crear un nuevo caso
  Future<Map<String, dynamic>> createCase({
    required String serenityId,
    required String userId,
    required String arteId,
  }) async {
    try {
      final response = await client.from('cases').insert({
        'serenity_id': serenityId,
        'user_id': userId,
        'arte_id': arteId,
        'active': true,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      return response;
    } catch (e) {
      throw Exception('Error al crear caso: $e');
    }
  }

  /// Obtener todos los casos
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

  /// Obtener casos activos
  Future<List<Map<String, dynamic>>> getActiveCases() async {
    try {
      final response = await client
          .from('cases')
          .select()
          .eq('active', true)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener casos activos: $e');
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
      throw Exception('Error al obtener casos por serenity_id: $e');
    }
  }

  /// Obtener casos por arte_id
  Future<List<Map<String, dynamic>>> getCasesByArteId(String arteId) async {
    try {
      final response = await client
          .from('cases')
          .select()
          .eq('arte_id', arteId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener casos por arte_id: $e');
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
      print('Error obteniendo caso por ID: $e');
      return null;
    }
  }

  /// Actualizar el estado activo de un caso
  Future<void> updateCaseStatus(String caseId, bool isActive) async {
    try {
      await client
          .from('cases')
          .update({'active': isActive})
          .eq('id', caseId);
    } catch (e) {
      throw Exception('Error al actualizar estado del caso: $e');
    }
  }

  /// Actualizar serenity_id de un caso
  Future<void> updateCaseSerenityId(String caseId, String newSerenityId) async {
    try {
      await client
          .from('cases')
          .update({'serenity_id': newSerenityId})
          .eq('id', caseId);
    } catch (e) {
      throw Exception('Error al actualizar serenity_id del caso: $e');
    }
  }

  /// Actualizar arte_id de un caso
  Future<void> updateCaseArteId(String caseId, String newArteId) async {
    try {
      await client
          .from('cases')
          .update({'arte_id': newArteId})
          .eq('id', caseId);
    } catch (e) {
      throw Exception('Error al actualizar arte_id del caso: $e');
    }
  }

  /// Eliminar un caso (soft delete - marcarlo como inactivo)
  Future<void> deactivateCase(String caseId) async {
    try {
      await client
          .from('cases')
          .update({'active': false})
          .eq('id', caseId);
    } catch (e) {
      throw Exception('Error al desactivar caso: $e');
    }
  }

  /// Eliminar un caso permanentemente
  Future<void> deleteCase(String caseId) async {
    try {
      await client
          .from('cases')
          .delete()
          .eq('id', caseId);
    } catch (e) {
      throw Exception('Error al eliminar caso: $e');
    }
  }

  /// Obtener casos con información relacionada (joins)
  Future<List<Map<String, dynamic>>> getCasesWithDetails() async {
    try {
      final response = await client
          .from('cases')
          .select('''
            *,
            users!cases_user_id_fkey(email, rol)
          ''')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener casos con detalles: $e');
    }
  }

  /// Obtener estadísticas de casos
  Future<Map<String, dynamic>> getCasesStats() async {
    try {
      // Obtener casos totales
      final totalCases = await client
          .from('cases')
          .select();
      
      // Obtener casos activos
      final activeCases = await client
          .from('cases')
          .select()
          .eq('active', true);

      // Obtener casos inactivos
      final inactiveCases = await client
          .from('cases')
          .select()
          .eq('active', false);

      return {
        'total': totalCases.length,
        'active': activeCases.length,
        'inactive': inactiveCases.length,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas de casos: $e');
    }
  }

  /// Buscar casos por texto (en serenity_id o arte_id)
  Future<List<Map<String, dynamic>>> searchCases(String searchTerm) async {
    try {
      final response = await client
          .from('cases')
          .select()
          .or('serenity_id.ilike.%$searchTerm%,arte_id.ilike.%$searchTerm%')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al buscar casos: $e');
    }
  }

  // ========== MÉTODOS QUE TRABAJAN CON CaseModel ==========

  /// Crear un nuevo caso usando CaseModel
  Future<CaseModel> createCaseFromModel(CaseModel caseModel) async {
    try {
      final response = await client.from('cases').insert(caseModel.toJson()).select().single();
      return CaseModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear caso desde modelo: $e');
    }
  }

  /// Obtener todos los casos como CaseModel
  Future<List<CaseModel>> getAllCasesAsModels() async {
    try {
      final response = await client
          .from('cases')
          .select()
          .order('created_at', ascending: false);
      return response.map<CaseModel>((json) => CaseModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener casos como modelos: $e');
    }
  }

  /// Obtener casos activos como CaseModel
  Future<List<CaseModel>> getActiveCasesAsModels() async {
    try {
      final response = await client
          .from('cases')
          .select()
          .eq('active', true)
          .order('created_at', ascending: false);
      return response.map<CaseModel>((json) => CaseModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener casos activos como modelos: $e');
    }
  }

  /// Obtener un caso por ID como CaseModel
  Future<CaseModel?> getCaseByIdAsModel(String caseId) async {
    try {
      final response = await client
          .from('cases')
          .select()
          .eq('id', caseId)
          .single();
      return CaseModel.fromJson(response);
    } catch (e) {
      print('Error obteniendo caso por ID como modelo: $e');
      return null;
    }
  }

  /// Actualizar caso usando CaseModel
  Future<CaseModel> updateCaseFromModel(String caseId, CaseModel caseModel) async {
    try {
      final updateData = caseModel.toJson();
      updateData.remove('id'); // No actualizar el ID
      updateData.remove('created_at'); // No actualizar created_at
      
      final response = await client
          .from('cases')
          .update(updateData)
          .eq('id', caseId)
          .select()
          .single();
      return CaseModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar caso desde modelo: $e');
    }
  }
}