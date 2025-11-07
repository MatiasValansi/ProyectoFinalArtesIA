import 'package:firebase_auth/firebase_auth.dart';
import '../../database/user_service.dart';

class UserController {
  final UserService _userService;

  UserController(this._userService);

  Future<Map<String, dynamic>?> getUserInfo() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
      try {
        return await _userService.getUserByAuthUid(firebaseUser.uid);
      } catch (e) {
        throw Exception('Error obteniendo información del usuario: $e');
      }
    }
    return null;
  }
}
