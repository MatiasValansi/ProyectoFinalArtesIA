import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../supabase/supabase_config.dart';

class UserService {
  final SupabaseClient client = SupabaseConfig.client;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<void> createUser({
    required String email,
    required String password,
    required String rol,
  }) async {
    try {
      // 1️⃣ Crear usuario en Firebase Auth
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = userCredential.user!.uid;

      // 2️⃣ Insertar registro en Supabase
      await client.from('users').insert({
        'auth_uid': uid,
        'email': email,
        'rol': rol.toUpperCase(),
      });
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await client.from('users').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    await client.from('users').update({'rol': newRole.toUpperCase()}).eq('id', userId);
  }

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
      print('Error obteniendo usuario por auth_uid: $e');
      return null;
    }
  }
}
