import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pixel_model.dart';
import 'pixel_service.dart';

/// Soporte offline (spec 12.2): guarda la última grid cargada para
/// mostrarla si no hay conexión, y encola acciones (likes, comentarios)
/// hechas sin conexión para sincronizarlas cuando vuelve.
///
/// Usa Hive (ya estaba en pubspec desde el Sprint 1) para persistencia
/// local liviana — no es una base de datos relacional, solo dos "cajas":
///   - `grid_cache`: último snapshot de píxeles vistos (JSON).
///   - `pending_actions`: cola FIFO de acciones a reintentar.
class OfflineService {
  OfflineService._();
  static final OfflineService instance = OfflineService._();

  static const _gridBoxName = 'grid_cache';
  static const _queueBoxName = 'pending_actions';
  static const _gridCacheKey = 'last_snapshot';

  Box? _gridBox;
  Box? _queueBox;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isFlushing = false;

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      _gridBox = await Hive.openBox(_gridBoxName);
      _queueBox = await Hive.openBox(_queueBoxName);

      _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
        final hasConnection = results.any((r) => r != ConnectivityResult.none);
        if (hasConnection) flushPendingActions();
      });
    } catch (_) {
      // Si Hive no puede inicializar (ej. plataforma no soportada), la
      // app sigue funcionando 100% online, solo sin cache/cola offline.
    }
  }

  Future<bool> get hasConnection async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  // --- Cache de la grilla ---

  Future<void> cacheGridSnapshot(Iterable<PixelModel> pixels) async {
    if (_gridBox == null) return;
    try {
      final jsonList = pixels.map((p) => p.toJson()).toList();
      await _gridBox!.put(_gridCacheKey, jsonEncode(jsonList));
    } catch (_) {
      // Cache es un "nice to have" — nunca debe romper el flujo principal.
    }
  }

  List<PixelModel> getCachedGridSnapshot() {
    final raw = _gridBox?.get(_gridCacheKey) as String?;
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => PixelModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // --- Cola de acciones pendientes ---

  Future<void> queueLikeAction(String pixelId) async {
    await _queueBox?.add({
      'type': 'like',
      'pixel_id': pixelId,
      'queued_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> queueCommentAction(String pixelId, String message) async {
    await _queueBox?.add({
      'type': 'comment',
      'pixel_id': pixelId,
      'message': message,
      'queued_at': DateTime.now().toIso8601String(),
    });
  }

  int get pendingCount => _queueBox?.length ?? 0;

  /// Reintenta cada acción encolada contra la API real. Las que fallan se
  /// dejan en la cola para el próximo intento; las que tienen éxito se
  /// remueven. Se llama automáticamente al detectar reconexión, y también
  /// puede llamarse manualmente (ej. pull-to-refresh).
  Future<void> flushPendingActions() async {
    if (_isFlushing || _queueBox == null || _queueBox!.isEmpty) return;
    _isFlushing = true;

    try {
      final keys = _queueBox!.keys.toList();
      for (final key in keys) {
        final action = _queueBox!.get(key) as Map?;
        if (action == null) continue;

        try {
          switch (action['type']) {
            case 'like':
              await PixelService.instance.toggleLike(action['pixel_id'] as String);
              break;
            case 'comment':
              await PixelService.instance.addComment(
                pixelId: action['pixel_id'] as String,
                message: action['message'] as String,
              );
              break;
          }
          await _queueBox!.delete(key);
        } catch (_) {
          // Sigue fallando (ej. endpoint aún no existe en el backend, o
          // seguimos sin señal) — se queda en la cola para el próximo
          // intento, no se pierde.
        }
      }
    } finally {
      _isFlushing = false;
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}
