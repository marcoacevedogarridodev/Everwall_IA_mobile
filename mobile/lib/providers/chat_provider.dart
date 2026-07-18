import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/api_exception.dart';
import '../services/pixel_service.dart';
import '../services/websocket_service.dart';

enum ChatListStatus { loading, loaded, empty, error }
enum ChatThreadStatus { loading, loaded, error }

/// Estado del sistema de mensajería (spec sección 6): lista de
/// conversaciones + el hilo actualmente abierto, con actualización en
/// tiempo real vía WebSocketService (best-effort, ver nota en ese archivo).
class ChatProvider extends ChangeNotifier {
  final _pixelService = PixelService.instance;
  final _wsService = WebSocketService.instance;
  StreamSubscription<MessageModel>? _wsSubscription;

  String? _currentUserId;

  // --- Lista de conversaciones ---
  ChatListStatus _listStatus = ChatListStatus.loading;
  List<ChatSummaryModel> _chats = [];
  String? _listError;

  ChatListStatus get listStatus => _listStatus;
  List<ChatSummaryModel> get chats => _chats;
  String? get listError => _listError;

  // --- Hilo activo ---
  ChatThreadStatus _threadStatus = ChatThreadStatus.loading;
  String? _activePixelId;
  List<MessageModel> _messages = [];
  String? _threadError;
  bool _isSending = false;

  ChatThreadStatus get threadStatus => _threadStatus;
  List<MessageModel> get messages => _messages;
  String? get threadError => _threadError;
  bool get isSending => _isSending;

  /// Debe llamarse una vez al iniciar sesión (ver AuthProvider) para que
  /// `MessageModel.isMine` se calcule bien y el WebSocket se conecte
  /// autenticado.
  void configure({required String userId, required String accessToken}) {
    _currentUserId = userId;
    _wsService.connect(accessToken);
    _wsSubscription ??= _wsService.onMessage.listen(_onSocketMessage);
  }

  void _onSocketMessage(MessageModel message) {
    if (message.pixelId != _activePixelId) return;
    // Evita duplicar el mensaje si ya lo agregamos optimistamente al enviar.
    if (_messages.any((m) => m.id == message.id)) return;
    _messages = [..._messages, message];
    notifyListeners();
  }

  Future<void> loadChatList() async {
    _listStatus = ChatListStatus.loading;
    notifyListeners();
    try {
      final chats = await _pixelService.getChatList();
      _chats = chats;
      _listStatus = chats.isEmpty ? ChatListStatus.empty : ChatListStatus.loaded;
    } on ApiException catch (e) {
      _listError = e.message;
      _listStatus = ChatListStatus.error;
    }
    notifyListeners();
  }

  Future<void> openChat(String pixelId) async {
    if (_activePixelId != null && _activePixelId != pixelId) {
      _wsService.leavePixelChat(_activePixelId!);
    }
    _activePixelId = pixelId;
    _threadStatus = ChatThreadStatus.loading;
    _messages = [];
    notifyListeners();

    _wsService.joinPixelChat(pixelId);

    try {
      final messages = await _pixelService.getMessages(
        pixelId,
        currentUserId: _currentUserId,
      );
      _messages = messages;
      _threadStatus = ChatThreadStatus.loaded;
    } on ApiException catch (e) {
      _threadError = e.message;
      _threadStatus = ChatThreadStatus.error;
    }
    notifyListeners();
  }

  void closeChat() {
    if (_activePixelId != null) {
      _wsService.leavePixelChat(_activePixelId!);
    }
    _activePixelId = null;
    _messages = [];
  }

  Future<bool> sendMessage(String text, {required bool isPrivate}) async {
    final pixelId = _activePixelId;
    if (pixelId == null || text.trim().isEmpty) return false;

    _isSending = true;
    notifyListeners();

    try {
      final sent = await _pixelService.sendMessage(
        pixelId: pixelId,
        message: text.trim(),
        isPrivate: isPrivate,
        currentUserId: _currentUserId,
      );
      _messages = [..._messages, sent];
      return true;
    } on ApiException catch (e) {
      _threadError = e.message;
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Limpia toda la sesión de chat (llamado desde ProfileScreen al hacer
  /// logout) para que el próximo usuario que inicie sesión en el mismo
  /// dispositivo no vea datos ni conexión del anterior.
  void reset() {
    closeChat();
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wsService.disconnect();
    _currentUserId = null;
    _chats = [];
    _listStatus = ChatListStatus.loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _wsService.disconnect();
    super.dispose();
  }
}
