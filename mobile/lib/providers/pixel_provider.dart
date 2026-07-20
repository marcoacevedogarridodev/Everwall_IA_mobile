import 'package:flutter/material.dart';
import '../models/pixel_model.dart';
import '../services/analytics_service.dart';
import '../services/offline_service.dart';
import '../services/pixel_service.dart';

/// Estado del píxel actualmente seleccionado (overlay de long-press,
/// Pixel Detail Screen). Separado de GridProvider porque su ciclo de vida
/// es distinto: GridProvider vive toda la sesión, esto vive mientras el
/// overlay/detail está abierto.
class PixelProvider extends ChangeNotifier {
  final _pixelService = PixelService.instance;

  PixelModel? _selected;

  PixelModel? get selected => _selected;

  void select(PixelModel pixel) {
    _selected = pixel;
    notifyListeners();
  }

  void clear() {
    _selected = null;
    notifyListeners();
  }

  /// Toggle optimista de like sobre el píxel seleccionado: aplica el
  /// cambio en la UI al instante y confirma contra
  /// `POST /pixels/toggle_like/` (endpoint PROPUESTO — ver
  /// PENDING_BACKEND_ENDPOINTS.md). Si el backend responde con un
  /// contador distinto al optimista, se corrige silenciosamente.
  ///
  /// Sprint 9 — soporte offline: si no hay conexión, la acción se encola
  /// en `OfflineService` y se sincroniza sola al reconectar, en vez de
  /// intentar la request (que fallaría seguro) y revertir el cambio.
  Future<void> toggleLikeOptimistic() async {
    final pixel = _selected;
    if (pixel == null) return;

    final optimisticLiked = !pixel.isLikedByMe;
    final previous = pixel;

    _selected = pixel.copyWith(
      isLikedByMe: optimisticLiked,
      likesCount: pixel.likesCount + (optimisticLiked ? 1 : -1),
    );
    notifyListeners();

    if (optimisticLiked) {
      AnalyticsService.instance.logLikeGiven(pixel.id);
    }

    if (!await OfflineService.instance.hasConnection) {
      await OfflineService.instance.queueLikeAction(pixel.id);
      return; // se mantiene el estado optimista, se sincroniza al volver la señal
    }

    try {
      final result = await _pixelService.toggleLike(pixel.id);
      // Solo corrige si sigue siendo el píxel seleccionado (evita pisar
      // una selección nueva si el usuario ya navegó a otro píxel).
      if (_selected?.id == pixel.id) {
        _selected = _selected!.copyWith(
          isLikedByMe: result.isLiked,
          likesCount: result.likesCount,
        );
        notifyListeners();
      }
    } catch (_) {
      // Rollback: el endpoint aún no existe en el backend real o falló
      // por otra razón (no por falta de conexión, ya la validamos arriba).
      if (_selected?.id == pixel.id) {
        _selected = previous;
        notifyListeners();
      }
    }
  }
}
