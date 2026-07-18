/// Modelos del sistema de mensajería (spec sección 6), sobre
/// GET/POST /pixels/share_pixel/.
///
/// NOTA IMPORTANTE: solo tenemos un par de endpoints (GET/POST
/// share_pixel/) para todo el sistema de chat — no hay uno separado para
/// "lista de conversaciones" vs "mensajes de una conversación puntual".
/// Asumí que:
///   - `GET /pixels/share_pixel/`             -> lista de conversaciones
///     (una por píxel con el que el usuario tiene mensajes), para Chat List.
///   - `GET /pixels/share_pixel/?pixel_id=X`  -> mensajes de esa
///     conversación puntual, para Chat Detail.
///   - `POST /pixels/share_pixel/`            -> enviar mensaje
///     `{ pixel_id, message, is_private }`.
///
/// Ver PENDING_BACKEND_ENDPOINTS.md para el detalle completo y ajustar si
/// el formato real difiere — todo el parsing vive en este único archivo.
library;

class MessageModel {
  final String id;
  final String pixelId;
  final String senderId;
  final String senderName;
  final String message;
  final bool isPrivate;
  final bool isMine;
  final DateTime? createdAt;

  const MessageModel({
    required this.id,
    required this.pixelId,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.isPrivate = false,
    this.isMine = false,
    this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final senderId = (json['sender_id'] ?? json['sender'] ?? '').toString();
    return MessageModel(
      id: (json['id'] ?? '').toString(),
      pixelId: (json['pixel_id'] ?? json['pixel'] ?? '').toString(),
      senderId: senderId,
      senderName: json['sender_name'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isPrivate: json['is_private'] as bool? ?? false,
      isMine: currentUserId != null && senderId == currentUserId,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

/// Resumen de una conversación para Chat List Screen.
class ChatSummaryModel {
  final String pixelId;
  final String pixelImageUrl;
  final String pixelOwnerName;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ChatSummaryModel({
    required this.pixelId,
    required this.pixelImageUrl,
    required this.pixelOwnerName,
    required this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ChatSummaryModel.fromJson(Map<String, dynamic> json) {
    return ChatSummaryModel(
      pixelId: (json['pixel_id'] ?? json['pixel'] ?? '').toString(),
      pixelImageUrl: json['pixel_image_url'] as String? ??
          json['pixel_image'] as String? ??
          '',
      pixelOwnerName: json['pixel_owner_name'] as String? ?? '',
      lastMessage: json['last_message'] as String? ?? '',
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString())
          : null,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}
