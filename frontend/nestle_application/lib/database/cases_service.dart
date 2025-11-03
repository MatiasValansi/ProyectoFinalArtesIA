import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import '../models/case_model.dart';

class CasesService {
  final SupabaseClient client = SupabaseConfig.client;

  /// Crear un nuevo caso
  Future<Map<String, dynamic>> createCase({
    required String name,
    required String serenityId,
    required String userId,
    required List<String> arteId,
    bool? approved,
    Map<String, dynamic>? problems,
    double? score,
    String? recommendations,
    String? imageUrl,
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
        if (imageUrl != null) 'image_url': imageUrl,
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
      
      // Normalizar la respuesta para asegurar consistencia
      return List<Map<String, dynamic>>.from(response).map((caseData) {
        // Asegurar que user_id siempre tenga una estructura válida
        final userData = caseData['user_id'];
        if (userData == null || userData is! Map) {
          caseData['user_id'] = {
            'id': 'unknown',
            'email': 'usuario@desconocido.com',
            'rol': 'user',
          };
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
          .contains('arte_id', [arteId]) // Buscar dentro del array
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
  Future<void> updateCaseArteId(String caseId, List<String> newArteId) async {
    try {
      await client
          .from('cases')
          .update({'arte_id': newArteId})
          .eq('id', caseId);
    } catch (e) {
      throw Exception('Error al actualizar arte_id del caso: $e');
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


  /// Actualizar problemas de un caso
  Future<void> updateCaseProblems(String caseId, Map<String, dynamic> problems) async {
    try {
      await client
          .from('cases')
          .update({'problems': problems})
          .eq('id', caseId);
    } catch (e) {
      throw Exception('Error al actualizar problemas del caso: $e');
    }
  }

  /// Actualizar score de un caso
  Future<void> updateCaseScore(String caseId, double score) async {
    try {
      await client
          .from('cases')
          .update({'score': score})
          .eq('id', caseId);
    } catch (e) {
      throw Exception('Error al actualizar score del caso: $e');
    }
  }

  /// Actualizar recomendaciones de un caso
  Future<void> updateCaseRecommendations(String caseId, String recommendations) async {
    try {
      await client
          .from('cases')
          .update({'recommendations': recommendations})
          .eq('id', caseId);
    } catch (e) {
      throw Exception('Error al actualizar recomendaciones del caso: $e');
    }
  }

  /// Actualizar análisis completo de un caso (nuevos campos)
  Future<void> updateCaseAnalysis({
    required String caseId,
    bool? approved,

    Map<String, dynamic>? problems,
    double? score,
    String? recommendations,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (approved != null) updateData['approved'] = approved;
      // Eliminamos total_images - se calcula desde arte_id
      if (problems != null) updateData['problems'] = problems;
      if (score != null) updateData['score'] = score;
      if (recommendations != null) updateData['recommendations'] = recommendations;

      if (updateData.isNotEmpty) {
        await client
            .from('cases')
            .update(updateData)
            .eq('id', caseId);
      }
    } catch (e) {
      throw Exception('Error al actualizar análisis del caso: $e');
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

  /// Obtener casos aprobados
  Future<List<Map<String, dynamic>>> getApprovedCases() async {
    try {
      final response = await client
          .from('cases')
          .select()
          .eq('approved', true)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener casos aprobados: $e');
    }
  }

  /// Obtener casos pendientes de aprobación
  Future<List<Map<String, dynamic>>> getPendingApprovalCases() async {
    try {
      final response = await client
          .from('cases')
          .select()
          .or('approved.is.null,approved.eq.false')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener casos pendientes de aprobación: $e');
    }
  }

  /// Obtener casos con score mayor a un valor
  Future<List<Map<String, dynamic>>> getCasesByMinScore(double minScore) async {
    try {
      final response = await client
          .from('cases')
          .select()
          .gte('score', minScore)
          .order('score', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener casos por score mínimo: $e');
    }
  }

  /// Obtener casos con problemas específicos
  Future<List<Map<String, dynamic>>> getCasesWithProblems() async {
    try {
      final response = await client
          .from('cases')
          .select()
          .not('problems', 'is', null)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener casos con problemas: $e');
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

      // Obtener casos aprobados
      final approvedCases = await client
          .from('cases')
          .select()
          .eq('approved', true);

      // Obtener casos pendientes de aprobación
      final pendingCases = await client
          .from('cases')
          .select()
          .or('approved.is.null,approved.eq.false');

      // Obtener casos con problemas
      final casesWithProblems = await client
          .from('cases')
          .select()
          .not('problems', 'is', null);

      // Calcular score promedio
      final casesWithScore = await client
          .from('cases')
          .select('score')
          .not('score', 'is', null);
      
      double averageScore = 0.0;
      if (casesWithScore.isNotEmpty) {
        final scores = casesWithScore.map((caseData) => (caseData['score'] as num).toDouble()).toList();
        averageScore = scores.reduce((a, b) => a + b) / scores.length;
      }

      return {
        'total': totalCases.length,
        'active': activeCases.length,
        'inactive': inactiveCases.length,
        'approved': approvedCases.length,
        'pending': pendingCases.length,
        'withProblems': casesWithProblems.length,
        'averageScore': averageScore,
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

  /// Obtener casos aprobados como CaseModel
  Future<List<CaseModel>> getApprovedCasesAsModels() async {
    try {
      final response = await client
          .from('cases')
          .select()
          .eq('approved', true)
          .order('created_at', ascending: false);
      return response.map<CaseModel>((json) => CaseModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener casos aprobados como modelos: $e');
    }
  }

  /// Obtener casos pendientes de aprobación como CaseModel
  Future<List<CaseModel>> getPendingApprovalCasesAsModels() async {
    try {
      final response = await client
          .from('cases')
          .select()
          .or('approved.is.null,approved.eq.false')
          .order('created_at', ascending: false);
      return response.map<CaseModel>((json) => CaseModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener casos pendientes como modelos: $e');
    }
  }

  /// Obtener casos por score mínimo como CaseModel
  Future<List<CaseModel>> getCasesByMinScoreAsModels(double minScore) async {
    try {
      final response = await client
          .from('cases')
          .select()
          .gte('score', minScore)
          .order('score', ascending: false);
      return response.map<CaseModel>((json) => CaseModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener casos por score como modelos: $e');
    }
  }

  /// Obtener casos con problemas como CaseModel
  Future<List<CaseModel>> getCasesWithProblemsAsModels() async {
    try {
      final response = await client
          .from('cases')
          .select()
          .not('problems', 'is', null)
          .order('created_at', ascending: false);
      return response.map<CaseModel>((json) => CaseModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener casos con problemas como modelos: $e');
    }
  }

  // ========== MÉTODOS DE ANÁLISIS Y GESTIÓN AVANZADA ==========

  /// Marcar un caso como completamente analizado
  Future<CaseModel> markCaseAsAnalyzed({
    required String caseId,
    required bool approved,
    Map<String, dynamic>? problems,
    double? score,
    String? recommendations,
  }) async {
    try {
      await updateCaseAnalysis(
        caseId: caseId,
        approved: approved,
        problems: problems,
        score: score,
        recommendations: recommendations,
      );
      
      final updatedCase = await getCaseByIdAsModel(caseId);
      if (updatedCase == null) {
        throw Exception('No se pudo obtener el caso actualizado');
      }
      
      return updatedCase;
    } catch (e) {
      throw Exception('Error al marcar caso como analizado: $e');
    }
  }

  /// Obtener resumen de análisis para un caso
  Future<Map<String, dynamic>?> getCaseAnalysisSummary(String caseId) async {
    try {
      final response = await client
          .from('cases')
          .select('approved, arte_id, problems, score, recommendations')
          .eq('id', caseId)
          .single();
      
      final arteIdArray = response['arte_id'] as List<dynamic>? ?? [];
  
      return {
        'approved': response['approved'],
        'totalImages': arteIdArray.length,
        'problems': response['problems'],
        'score': response['score'],
        'recommendations': response['recommendations'],
        'hasAnalysis': response['approved'] != null || 
                       arteIdArray.isNotEmpty ||
                       response['problems'] != null ||
                       response['score'] != null ||
                       response['recommendations'] != null,
      };
    } catch (e) {
      print('Error obteniendo resumen de análisis: $e');
      return null;
    }
  }

  /// Limpiar análisis de un caso (resetear campos de análisis)
  Future<void> clearCaseAnalysis(String caseId) async {
    try {
      await client
          .from('cases')
          .update({
            'approved': null,
            'problems': null,
            'score': null,
            'recommendations': null,
          })
          .eq('id', caseId);
    } catch (e) {
      throw Exception('Error al limpiar análisis del caso: $e');
    }
  }
}