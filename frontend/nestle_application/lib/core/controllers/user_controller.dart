import 'package:firebase_auth/firebase_auth.dart';
import '../../database/user_service.dart';
import '../../models/user_model.dart';

class UserController {
  final UserService _userService;

  UserController(this._userService);

  Future<UserModel?> getUserInfo() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
      try {
        return await _userService.getUserByAuthUidAsModel(firebaseUser.uid);
      } catch (e) {
        print('Error obteniendo información del usuario: $e');
      }
    }
    return null;
  }
}