import 'package:firebase_auth/firebase_auth.dart';
import '../../database/user_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  
  Map<String, dynamic>? _currentUserData;

  /// Obtiene los datos del usuario actual desde Supabase
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (_currentUserData != null) {
      return _currentUserData;
    }

    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    try {
      // Buscar usuario en Supabase por auth_uid
      final userData = await _userService.getUserByAuthUid(firebaseUser.uid);

      if (userData != null) {
        _currentUserData = userData;
        return _currentUserData;
      }
    } catch (e) {
      print('Error obteniendo datos del usuario: $e');
    }

    return null;
  }

  /// Verifica si el usuario actual es administrador
  Future<bool> isCurrentUserAdmin() async {
    final userData = await getCurrentUserData();
    return userData?['rol']?.toString().toUpperCase() == 'ADMINISTRADOR';
  }

  /// Obtiene el rol del usuario actual
  Future<String?> getCurrentUserRole() async {
    final userData = await getCurrentUserData();
    return userData?['rol']?.toString();
  }

  /// Obtiene el email del usuario actual
  Future<String?> getCurrentUserEmail() async {
    final userData = await getCurrentUserData();
    return userData?['email']?.toString();
  }

  /// Limpia la caché de datos del usuario (útil al hacer logout)
  void clearUserData() {
    _currentUserData = null;
  }

  /// Inicia sesión con email y password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Clear cache to force refresh of user data
      clearUserData();
      return true;
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }

  /// Cierra sesión
  Future<void> signOut() async {
    try {
      clearUserData();
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error al cerrar sesión: $e');
      // Aún así limpiamos los datos locales
      clearUserData();
    }
  }
}