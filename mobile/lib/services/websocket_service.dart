import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';
import '../models/message_model.dart';

/// Conexión WebSocket para mensajes en tiempo real (spec sección 6 /
/// arquitectura `services/websocket_service.dart`).
///
/// ⚠️ CONTRATO PROPUESTO — no confirmado con el backend todavía (no vi un
/// endpoint/protocolo de WebSocket en tu lista de rutas REST). Documentado
/// también en PENDING_BACKEND_ENDPOINTS.md. Mientras no exista el servidor
/// de sockets, la app sigue funcionando 100% vía REST (`PixelService.
/// sendMessage` / `getMessages`) — el WebSocket es solo un "plus" para que
/// los mensajes lleguen sin refrescar manualmente; si la conexión falla,
/// se reintenta en silencio y el chat sigue usable por REST.
///
/// Contrato propuesto:
///   Conexión: `wss://tu-api.com/ws` (namespace por defecto), auth vía
///     `{ auth: { token: <access_token> } }` en el handshake.
///   Cliente -> Servidor:
///     - `join_pixel_chat`   { pixel_id }
///     - `leave_pixel_chat`  { pixel_id }
///   Servidor -> Cliente:
///     - `new_message`       { ...MessageModel en JSON... }
class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  io.Socket? _socket;
  final _messageController = StreamController<MessageModel>.broadcast();

  /// Stream de mensajes nuevos recibidos por socket, sin filtrar por
  /// pixelId — el caller (ChatProvider) filtra por la conversación abierta.
  Stream<MessageModel> get onMessage => _messageController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String accessToken) {
    if (_socket != null) return;

    _socket = io.io(
      AppConfig.wsBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.on('new_message', (data) {
      try {
        final json = Map<String, dynamic>.from(data as Map);
        _messageController.add(MessageModel.fromJson(json));
      } catch (_) {
        // Payload inesperado del servidor — se ignora sin romper el stream.
      }
    });

    _socket!.onConnectError((_) {
      // Silencioso a propósito: el chat sigue funcionando por REST aunque
      // el WebSocket no esté disponible (endpoint aún no confirmado).
    });
  }

  void joinPixelChat(String pixelId) {
    _socket?.emit('join_pixel_chat', {'pixel_id': pixelId});
  }

  void leavePixelChat(String pixelId) {
    _socket?.emit('leave_pixel_chat', {'pixel_id': pixelId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
