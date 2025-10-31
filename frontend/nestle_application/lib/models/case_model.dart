class CaseModel {
  final String? id;
  final String name;
  final String serenityId;
  final String userId;
  final List<String> arteId;
  final DateTime? createdAt;
  final bool? approved;
  final int? totalImages;
  final Map<String, dynamic>? problems;
  final double? score;
  final String? recommendations;

  CaseModel({
    this.id,
    required this.name,
    required this.serenityId,
    required this.userId,
    required this.arteId,
    this.createdAt,
    this.approved,
    this.totalImages,
    this.problems,
    this.score,
    this.recommendations,
  });

  /// Factory constructor para crear una instancia desde JSON
  factory CaseModel.fromJson(Map<String, dynamic> json) {
    // Manejar arte_id como array
    List<String> arteIdList = [];
    if (json['arte_id'] != null) {
      if (json['arte_id'] is List) {
        arteIdList = List<String>.from(json['arte_id']);
      } else if (json['arte_id'] is String) {
        arteIdList = [json['arte_id']];
      }
    }
    
    return CaseModel(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      serenityId: json['serenity_id'] ?? '',
      userId: json['user_id'] ?? '',
      arteId: arteIdList,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      approved: json['approved'],
      totalImages: json['total_images']?.toInt(),
      problems: json['problems'] as Map<String, dynamic>?,
      score: json['score']?.toDouble(),
      recommendations: json['recommendations'],
    );
  }

  /// Convertir la instancia a JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'serenity_id': serenityId,
      'user_id': userId,
      'arte_id': arteId, // Ya es una lista, se serializa correctamente
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (approved != null) 'approved': approved,
      if (totalImages != null) 'total_images': totalImages,
      if (problems != null) 'problems': problems,
      if (score != null) 'score': score,
      if (recommendations != null) 'recommendations': recommendations,
    };
  }

  /// Crear una copia de la instancia con algunos campos modificados
  CaseModel copyWith({
    String? id,
    String? name,
    String? serenityId,
    String? userId,
    List<String>? arteId,
    DateTime? createdAt,
    bool? active,
    bool? approved,
    int? totalImages,
    Map<String, dynamic>? problems,
    double? score,
    String? recommendations,
  }) {
    return CaseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      serenityId: serenityId ?? this.serenityId,
      userId: userId ?? this.userId,
      arteId: arteId ?? this.arteId,
      createdAt: createdAt ?? this.createdAt,
      approved: approved ?? this.approved,
      totalImages: totalImages ?? this.totalImages,
      problems: problems ?? this.problems,
      score: score ?? this.score,
      recommendations: recommendations ?? this.recommendations,
    );
  }

  @override
  String toString() {
    return 'CaseModel(id: $id, name: $name, serenityId: $serenityId, userId: $userId, arteId: $arteId, createdAt: $createdAt, approved: $approved, totalImages: $totalImages, problems: $problems, score: $score, recommendations: $recommendations)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is CaseModel &&
      other.id == id &&
      other.name == name &&
      other.serenityId == serenityId &&
      other.userId == userId &&
      _listEquals(other.arteId, arteId) &&
      other.createdAt == createdAt &&
      other.approved == approved &&
      other.totalImages == totalImages &&
      _mapEquals(other.problems, problems) &&
      other.score == score &&
      other.recommendations == recommendations;
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  /// Helper method to compare maps
  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final K key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      serenityId.hashCode ^
      userId.hashCode ^
      Object.hashAll(arteId) ^
      createdAt.hashCode ^
      approved.hashCode ^
      totalImages.hashCode ^
      (problems?.hashCode ?? 0) ^
      score.hashCode ^
      recommendations.hashCode;
  }
}