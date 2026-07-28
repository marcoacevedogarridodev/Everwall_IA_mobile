import 'package:flutter/material.dart';
import '../../models/pixel_model.dart';
import 'pixel_card_widget.dart';

/// Envuelve [PixelCardWidget] con una transición sutil (fade + scale) cada
/// vez que el [pixel] que le pasa el padre cambia.
///
/// No decide por sí mismo qué imagen mostrar ni maneja timers propios —
/// eso lo controla InfiniteGridWidget, que solo intercambia 1-2 pares de
/// celdas por tick (no toda la grilla de golpe) para que el efecto se
/// sienta como una pared que respira, no como un refresh masivo.
class RotatingPixelCardWidget extends StatelessWidget {
  final PixelModel? pixel;
  final double size;

  const RotatingPixelCardWidget({
    super.key,
    required this.pixel,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 900),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            // Escala sutil (0.94 -> 1.0) en vez de solo fade: da sensación
            // de disolución suave en vez de un corte seco entre imágenes.
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.center,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      child: PixelCardWidget(
        key: ValueKey(pixel?.id ?? 'empty'),
        pixel: pixel,
        size: size,
      ),
    );
  }
}