/// Modelo de un píxel comprado en la grilla.
///
/// NOTA: como con UserModel, el parsing asume nombres de campo típicos
/// de DRF (snake_case). Si `GET /pixels/grid_status/` devuelve otro
/// formato, este es el único lugar que hay que ajustar.
class PixelModel {
  final String id;
  final int x;
  final int y;
  final String imageUrl;
  final String ownerName;
  final String ownerMessage;
  final int likesCount;
  final bool isLikedByMe;
  final int commentsCount;
  final bool isOwner;
  final DateTime? createdAt;

  const PixelModel({
    required this.id,
    required this.x,
    required this.y,
    required this.imageUrl,
    required this.ownerName,
    required this.ownerMessage,
    this.likesCount = 0,
    this.isLikedByMe = false,
    this.commentsCount = 0,
    this.isOwner = false,
    this.createdAt,
  });

  /// Clave única de posición, usada por GridProvider para cachear en un Map.
  String get positionKey => '$x,$y';

  /// Spec: >50 likes muestra el ícono 🔥 en la esquina superior derecha.
  bool get isOnFire => likesCount > 50;

  factory PixelModel.fromJson(Map<String, dynamic> json) {
    return PixelModel(
      id: (json['id'] ?? json['pk'] ?? '').toString(),
      x: (json['x'] as num?)?.toInt() ?? 0,
      y: (json['y'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String? ??
          json['image'] as String? ??
          '',
      ownerName: json['owner_name'] as String? ?? '',
      ownerMessage: json['owner_message'] as String? ?? '',
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      isLikedByMe:
          json['is_liked_by_me'] as bool? ?? json['is_liked'] as bool? ?? false,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      isOwner: json['is_owner'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Usado por OfflineService (Sprint 9) para cachear la grilla en Hive.
  /// Espejo de fromJson — si agregas un campo allá, agrégalo acá también.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'image_url': imageUrl,
      'owner_name': ownerName,
      'owner_message': ownerMessage,
      'likes_count': likesCount,
      'is_liked': isLikedByMe,
      'comments_count': commentsCount,
      'is_owner': isOwner,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  PixelModel copyWith({
    int? likesCount,
    bool? isLikedByMe,
    int? commentsCount,
  }) {
    return PixelModel(
      id: id,
      x: x,
      y: y,
      imageUrl: imageUrl,
      ownerName: ownerName,
      ownerMessage: ownerMessage,
      likesCount: likesCount ?? this.likesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      commentsCount: commentsCount ?? this.commentsCount,
      isOwner: isOwner,
      createdAt: createdAt,
    );
  }
}
