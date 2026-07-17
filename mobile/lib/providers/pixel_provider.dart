import 'package:flutter/material.dart';
import '../models/pixel_model.dart';

/// Estado del píxel actualmente seleccionado (overlay de long-press,
/// Pixel Detail Screen en Sprint 4). Separado de GridProvider porque su
/// ciclo de vida es distinto: GridProvider vive toda la sesión, esto vive
/// mientras el overlay/detail está abierto.
class PixelProvider extends ChangeNotifier {
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

  /// Toggle optimista de like sobre el píxel seleccionado. El endpoint de
  /// like no está en la lista de rutas que compartiste todavía — cuando lo
  /// tengamos, este método llama al PixelService real en vez de solo
  /// mutar el estado local (Sprint 7).
  void toggleLikeOptimistic() {
    final pixel = _selected;
    if (pixel == null) return;
    final liked = !pixel.isLikedByMe;
    _selected = pixel.copyWith(
      isLikedByMe: liked,
      likesCount: pixel.likesCount + (liked ? 1 : -1),
    );
    notifyListeners();
  }
}
