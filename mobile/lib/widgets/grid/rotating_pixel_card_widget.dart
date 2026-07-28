import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/pixel_model.dart';
import 'pixel_card_widget.dart';

/// Envuelve [PixelCardWidget] con un efecto puramente visual/decorativo
/// para la Grid Screen: cada [_interval] (3s), la celda hace un crossfade
/// hacia otra imagen tomada al azar del pool de imágenes actualmente
/// visibles en la grilla, y en el siguiente ciclo vuelve a fundir de
/// regreso a su imagen real — dando la sensación de una "pared viva" que
/// va cambiando.
///
/// IMPORTANTE: esto NUNCA toca los datos reales del píxel (id, x, y,
/// owner, likes) — solo la `imageUrl` que se pinta. El tap/long-press
/// sigue abriendo el detalle real de esa posición, tal cual estaba antes.
/// Las celdas vacías (`pixel == null`) no rotan.
class RotatingPixelCardWidget extends StatefulWidget {
  final PixelModel? pixel;
  final double size;
  final List<String> imagePool;

  const RotatingPixelCardWidget({
    super.key,
    required this.pixel,
    required this.size,
    required this.imagePool,
  });

  @override
  State<RotatingPixelCardWidget> createState() =>
      _RotatingPixelCardWidgetState();
}

class _RotatingPixelCardWidgetState extends State<RotatingPixelCardWidget> {
  static const _interval = Duration(seconds: 3);
  static const _fadeDuration = Duration(milliseconds: 700);

  final _random = Random();
  Timer? _timer;
  String? _displayUrl;

  @override
  void initState() {
    super.initState();
    _displayUrl = widget.pixel?.imageUrl;
    _scheduleNext();
  }

  @override
  void didUpdateWidget(covariant RotatingPixelCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si esta celda pasó a representar un píxel real distinto (ej. tras
    // un refetch), resetea a la imagen real antes de seguir rotando.
    if (oldWidget.pixel?.id != widget.pixel?.id) {
      _displayUrl = widget.pixel?.imageUrl;
      _scheduleNext();
    }
  }

  void _scheduleNext() {
    _timer?.cancel();
    if (widget.pixel == null) return; // celdas vacías no rotan
    _timer = Timer(_interval, _rotate);
  }

  void _rotate() {
    if (!mounted || widget.pixel == null) return;

    final pool = widget.imagePool.where((u) => u.isNotEmpty).toSet().toList();
    final ownUrl = widget.pixel!.imageUrl;

    if (pool.length < 2) {
      _scheduleNext();
      return;
    }

    final isShowingOwn = _displayUrl == ownUrl || _displayUrl == null;
    String next;

    if (isShowingOwn) {
      final candidates = pool.where((u) => u != ownUrl).toList();
      next = candidates.isEmpty
          ? ownUrl
          : candidates[_random.nextInt(candidates.length)];
    } else {
      next = ownUrl; // vuelve a la imagen real de esta celda
    }

    setState(() => _displayUrl = next);
    _scheduleNext();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pixel = widget.pixel;
    if (pixel == null) {
      return PixelCardWidget(pixel: null, size: widget.size);
    }

    final displayPixel =
        pixel.copyWithImageUrl(_displayUrl ?? pixel.imageUrl);

    return AnimatedSwitcher(
      duration: _fadeDuration,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.center,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      child: PixelCardWidget(
        key: ValueKey('${pixel.id}-${_displayUrl ?? pixel.imageUrl}'),
        pixel: displayPixel,
        size: widget.size,
      ),
    );
  }
}