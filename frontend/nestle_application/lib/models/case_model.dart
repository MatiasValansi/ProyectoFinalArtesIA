class CaseModel {
  final String? id;
  final String serenityId;
  final String userId;
  final String arteId;
  final DateTime? createdAt;
  final bool active;

  CaseModel({
    this.id,
    required this.serenityId,
    required this.userId,
    required this.arteId,
    this.createdAt,
    this.active = true,
  });

  /// Factory constructor para crear una instancia desde JSON
  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id']?.toString(),
      serenityId: json['serenity_id'] ?? '',
      userId: json['user_id'] ?? '',
      arteId: json['arte_id'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      active: json['active'] ?? true,
    );
  }

  /// Convertir la instancia a JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'serenity_id': serenityId,
      'user_id': userId,
      'arte_id': arteId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'active': active,
    };
  }

  /// Crear una copia de la instancia con algunos campos modificados
  CaseModel copyWith({
    String? id,
    String? serenityId,
    String? userId,
    String? arteId,
    DateTime? createdAt,
    bool? active,
  }) {
    return CaseModel(
      id: id ?? this.id,
      serenityId: serenityId ?? this.serenityId,
      userId: userId ?? this.userId,
      arteId: arteId ?? this.arteId,
      createdAt: createdAt ?? this.createdAt,
      active: active ?? this.active,
    );
  }

  @override
  String toString() {
    return 'CaseModel(id: $id, serenityId: $serenityId, userId: $userId, arteId: $arteId, createdAt: $createdAt, active: $active)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is CaseModel &&
      other.id == id &&
      other.serenityId == serenityId &&
      other.userId == userId &&
      other.arteId == arteId &&
      other.createdAt == createdAt &&
      other.active == active;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      serenityId.hashCode ^
      userId.hashCode ^
      arteId.hashCode ^
      createdAt.hashCode ^
      active.hashCode;
  }
}