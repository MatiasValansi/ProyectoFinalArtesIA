import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'supabase_config.dart';
import '../models/user_model.dart';

class UserService {
  final SupabaseClient client = SupabaseConfig.client;

  Future<void> createUser({
    required String email,
    required String password,
    required String rol,
  }) async {
    try {
      // Crear una instancia secundaria de Firebase App para crear usuarios sin afectar la sesión actual
      FirebaseApp? secondaryApp;
      
      try {
        // Intentar obtener la app secundaria si ya existe
        secondaryApp = Firebase.app('SecondaryApp');
      } catch (e) {
        // Si no existe, crear una nueva instancia
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
      }

      // Usar la instancia secundaria para crear el usuario
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      
      // 1️⃣ Crear usuario usando la instancia secundaria
      UserCredential userCredential = await secondaryAuth.createUserWithEmailAndPassword(
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

      // 3️⃣ Cerrar sesión de la instancia secundaria
      await secondaryAuth.signOut();
      
      // La sesión principal del administrador se mantiene intacta
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

  // ========== MÉTODOS QUE TRABAJAN CON UserModel ==========

  /// Crear un nuevo usuario usando UserModel (sin Firebase Auth)
  Future<UserModel> createUserFromModel(UserModel userModel) async {
    try {
      final response = await client.from('users').insert(userModel.toJson()).select().single();
      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear usuario desde modelo: $e');
    }
  }

  /// Obtener todos los usuarios como UserModel
  Future<List<UserModel>> getUsersAsModels() async {
    try {
      final response = await client.from('users').select();
      return response.map<UserModel>((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios como modelos: $e');
    }
  }

  /// Obtener un usuario por ID como UserModel
  Future<UserModel?> getUserByIdAsModel(String userId) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return UserModel.fromJson(response);
    } catch (e) {
      print('Error obteniendo usuario por ID como modelo: $e');
      return null;
    }
  }

  /// Obtener un usuario por auth_uid como UserModel
  Future<UserModel?> getUserByAuthUidAsModel(String authUid) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('auth_uid', authUid)
          .single();
      return UserModel.fromJson(response);
    } catch (e) {
      print('Error obteniendo usuario por auth_uid como modelo: $e');
      return null;
    }
  }

  /// Actualizar usuario usando UserModel
  Future<UserModel> updateUserFromModel(String userId, UserModel userModel) async {
    try {
      final updateData = userModel.toJson();
      updateData.remove('id'); // No actualizar el ID
      updateData.remove('auth_uid'); // No actualizar auth_uid
      updateData.remove('created_at'); // No actualizar created_at
      
      final response = await client
          .from('users')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();
      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar usuario desde modelo: $e');
    }
  }

  /// Obtener usuarios por rol como UserModel
  Future<List<UserModel>> getUsersByRoleAsModel(String role) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('rol', role.toUpperCase());
      return response.map<UserModel>((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios por rol como modelos: $e');
    }
  }

  /// Obtener estadísticas de usuarios por rol
  Future<Map<String, int>> getUsersStatsByRole() async {
    try {
      final users = await getUsersAsModels();
      final stats = <String, int>{};
      
      for (final user in users) {
        final role = user.rol.toUpperCase();
        stats[role] = (stats[role] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      throw Exception('Error al obtener estadísticas de usuarios: $e');
    }
  }

  /// Buscar usuarios por email
  Future<List<UserModel>> searchUsersByEmail(String emailPattern) async {
    try {
      final response = await client
          .from('users')
          .select()
          .ilike('email', '%$emailPattern%');
      return response.map<UserModel>((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al buscar usuarios por email: $e');
    }
  }
}
