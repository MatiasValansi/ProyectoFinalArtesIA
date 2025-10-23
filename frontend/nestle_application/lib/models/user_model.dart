class UserModel {
  final String? id;
  final String authUid;
  final String email;
  final String rol;
  final DateTime? createdAt;

  UserModel({
    this.id,
    required this.authUid,
    required this.email,
    required this.rol,
    this.createdAt,
  });

  /// Factory constructor para crear una instancia desde JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString(),
      authUid: json['auth_uid'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  /// Convertir la instancia a JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'auth_uid': authUid,
      'email': email,
      'rol': rol.toUpperCase(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Crear una copia de la instancia con algunos campos modificados
  UserModel copyWith({
    String? id,
    String? authUid,
    String? email,
    String? rol,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      authUid: authUid ?? this.authUid,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Verificar si el usuario es administrador
  bool get isAdmin => rol.toUpperCase() == 'ADMIN';

  /// Verificar si el usuario es supervisor
  bool get isSupervisor => rol.toUpperCase() == 'SUPERVISOR';

  /// Verificar si el usuario es operario
  bool get isOperario => rol.toUpperCase() == 'OPERARIO';

  /// Obtener el rol formateado para mostrar
  String get formattedRole {
    switch (rol.toUpperCase()) {
      case 'ADMIN':
        return 'Administrador';
      case 'SUPERVISOR':
        return 'Supervisor';
      case 'OPERARIO':
        return 'Operario';
      default:
        return rol;
    }
  }

  @override
  String toString() {
    return 'UserModel(id: $id, authUid: $authUid, email: $email, rol: $rol, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is UserModel &&
      other.id == id &&
      other.authUid == authUid &&
      other.email == email &&
      other.rol == rol &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      authUid.hashCode ^
      email.hashCode ^
      rol.hashCode ^
      createdAt.hashCode;
  }
}