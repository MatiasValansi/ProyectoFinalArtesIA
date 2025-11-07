import '../../core/auth/auth_service.dart';

class RoleController {
  final AuthService _authService;

  RoleController(this._authService);

  Future<Map<String, dynamic>> getUserRole() async {
    try {
      final isAdmin = await _authService.isCurrentUserAdmin();
      final isSupervisor = await _authService.isCurrentUserSupervisor();
      final role = await _authService.getCurrentUserRole();
      return {
        'isAdmin': isAdmin,
        'isSupervisor': isSupervisor,
        'role': role ?? '',
      };
    } catch (e) {
      return {'isAdmin': false, 'isSupervisor': false, 'role': ''};
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
