/// Comentario público sobre un píxel (spec sección 9.2).
///
/// ⚠️ Endpoint PROPUESTO — no estaba en tu lista de rutas reales. Sigue el
/// mismo protocolo que el resto de acciones bajo /pixels/ (mismo patrón
/// que `share_pixel`, `toggle_like`, etc). Ver PENDING_BACKEND_ENDPOINTS.md.
///
///   GET  /api/pixels/pixel_comments/?pixel_id=<id>
///   Response: [ { id, pixel_id, author_id, author_name, message, created_at }, ... ]
///
///   POST /api/pixels/pixel_comments/
///   Body: { "pixel_id": "<id>", "message": "<texto>" }
///   Response: el comentario creado, mismo formato que el GET.
class CommentModel {
  final String id;
  final String pixelId;
  final String authorId;
  final String authorName;
  final String message;
  final bool isMine;
  final DateTime? createdAt;

  const CommentModel({
    required this.id,
    required this.pixelId,
    required this.authorId,
    required this.authorName,
    required this.message,
    this.isMine = false,
    this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final authorId = (json['author_id'] ?? json['author'] ?? '').toString();
    return CommentModel(
      id: (json['id'] ?? '').toString(),
      pixelId: (json['pixel_id'] ?? json['pixel'] ?? '').toString(),
      authorId: authorId,
      authorName: json['author_name'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isMine: currentUserId != null && authorId == currentUserId,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
