class CaseModel {
  final String? id;
  final String name;
  final String serenityId;
  final String userId;
  final List<String> arteId;
  final DateTime? createdAt;
  final bool? approved;
  final int? totalImages;
  final dynamic problems;
  final double? score;
  final dynamic recommendations;
  final List<String>? imageUrls;

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
    this.imageUrls,
  });

  /// Factory constructor para crear una instancia desde JSON
  factory CaseModel.fromJson(Map<String, dynamic> json) {
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
      problems: json['problems'],
      score: json['score']?.toDouble(),
      recommendations: json['recommendations'],
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : null,
    );
  }

  /// Convertir la instancia a JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'serenity_id': serenityId,
      'user_id': userId,
      'arte_id': arteId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (approved != null) 'approved': approved,
      if (problems != null) 'problems': problems,
      if (score != null) 'score': score,
      if (recommendations != null) 'recommendations': recommendations,
      if (imageUrls != null) 'image_urls': imageUrls,
    };
  }

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
    List<String>? imageUrls,
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
      imageUrls: imageUrls ?? this.imageUrls,
    );
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
        _dynamicEquals(other.problems, problems) &&
        other.score == score &&
        _dynamicEquals(other.recommendations, recommendations);
  }

  /// Metodo auxiliar para comparar listas
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  /// Metodo auxiliar para comparar valores dinámicos
  bool _dynamicEquals(dynamic a, dynamic b) {
    if (a == null) return b == null;
    if (b == null) return false;

    // Si ambos son del mismo tipo, usar comparación directa
    if (a.runtimeType == b.runtimeType) {
      return a.toString() == b.toString();
    }

    // Para tipos diferentes, comparar como string
    return a.toString() == b.toString();
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
        (recommendations?.hashCode ?? 0);
  }
}
