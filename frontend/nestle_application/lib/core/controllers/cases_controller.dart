import '../../database/cases_service.dart';
import '../../models/case_model.dart';

class CasesController {
  final CasesService _casesService;

  CasesController(this._casesService);

  Future<List<CaseModel>> getUserCases(String userId) async {
    try {
      final casesData = await _casesService.getCasesByUser(userId);
      return casesData.map((json) => CaseModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllCasesForSupervisor() async {
    try {
      return await _casesService.getAllCasesWithUserInfo();
    } catch (e) {
      return [];
    }
  }
}
