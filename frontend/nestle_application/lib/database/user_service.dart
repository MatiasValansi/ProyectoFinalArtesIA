import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'supabase_config.dart';
import '../models/user_model.dart';

class UserService {
  final SupabaseClient client = SupabaseConfig.client;

  /// Crear usuario
  Future<void> createUser({
    required String email,
    required String password,
    required String rol,
  }) async {
    try {
      FirebaseApp? secondaryApp;
      try {
        secondaryApp = Firebase.app('SecondaryApp');
      } catch (e) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
      }
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      UserCredential userCredential = await secondaryAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      final String uid = userCredential.user!.uid;

      await client.from('users').insert({
        'auth_uid': uid,
        'email': email,
        'rol': rol.toUpperCase(),
      });

      await secondaryAuth.signOut();
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await client.from('users').select();
    return List<Map<String, dynamic>>.from(response);
  }

  /// Cambiar rol de usuario
  Future<void> updateUserRole(String userId, String newRole) async {
    await client
        .from('users')
        .update({'rol': newRole.toUpperCase()})
        .eq('id', userId);
  }

  /// Eliminar usuario
  Future<void> deleteUser(String userId) async {
    await client.from('users').delete().eq('id', userId);
  }

  Future<Map<String, dynamic>?> getUserByAuthUid(String authUid) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('auth_uid', authUid)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Obtener todos los usuarios
  Future<List<UserModel>> getUsersAsModels() async {
    try {
      final response = await client.from('users').select();
      return response
          .map<UserModel>((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios como modelos: $e');
    }
  }

  /// Obtener un usuario por auth_uid
  Future<UserModel?> getUserByAuthUidAsModel(String authUid) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('auth_uid', authUid)
          .single();
      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
