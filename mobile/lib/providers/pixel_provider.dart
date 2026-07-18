import 'package:flutter/material.dart';
import '../models/pixel_model.dart';
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
  /// contador distinto al optimista, se corrige silenciosamente; si la
  /// request falla, se revierte el cambio.
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
      // Rollback: el endpoint aún no existe en el backend real o falló.
      if (_selected?.id == pixel.id) {
        _selected = previous;
        notifyListeners();
      }
    }
  }
}
