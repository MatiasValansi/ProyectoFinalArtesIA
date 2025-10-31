import 'package:firebase_auth/firebase_auth.dart';
import '../../database/user_service.dart';

class AuthService {
  static final AuthService instancia = AuthService._internal();
  factory AuthService() => instancia;
  AuthService._internal();

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final UserService userService = UserService();

  /// Guardamos el usuario actual en caché
  Map<String, dynamic>? currentUserData;

  /// Obtenemos los datos del usuario actual desde Supabase
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (currentUserData != null) {
      return currentUserData;
    }

    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    try {
      // Buscamos el usuario en Supabase por auth_uid
      final userData = await userService.getUserByAuthUid(firebaseUser.uid);

      if (userData != null) {
        currentUserData = userData;
        return currentUserData;
      }
    } catch (e) {
      print('Error obteniendo datos del usuario: $e');
    }

    return null;
  }

  /// Verificamos si el usuario es administrador
  Future<bool> isCurrentUserAdmin() async {
    final userData = await getCurrentUserData();
    return userData?['rol']?.toString().toUpperCase() == 'ADMINISTRADOR';
  }

  /// Obtenemos el rol del usuario 
  Future<String?> getCurrentUserRole() async {
    final userData = await getCurrentUserData();
    return userData?['rol']?.toString();
  }

  /// Obtenemos el email del usuario 
  Future<String?> getCurrentUserEmail() async {
    final userData = await getCurrentUserData();
    return userData?['email']?.toString();
  }

  /// Limpia la caché de datos del usuario
  void clearUserData() {
    currentUserData = null;
  }

  /// Iniciar sesión
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Borramos caché de datos del usuario
      clearUserData();
      return true;
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      clearUserData();
      await firebaseAuth.signOut();
    } catch (e) {
      print('Error al cerrar sesión: $e');
      clearUserData();
    }
  }
}