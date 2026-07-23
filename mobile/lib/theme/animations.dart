import 'package:flutter/material.dart';

/// Duraciones y curvas de animación estandarizadas para toda la app.
/// Mantener todas las animaciones consistentes usando estas constantes
/// en vez de valores mágicos dispersos por las screens/widgets.
///
/// NOTA: el Splash Screen ya NO usa animaciones (spec: fondo negro + ícono
/// estático, sin glow/pulso/scale, para calzar 1:1 con el splash nativo).
/// Su piso de tiempo mínimo vive como constante local en
/// `screens/splash_screen.dart`, no acá.
class AppAnimations {
  AppAnimations._();

  // Duraciones
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // Curvas
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve sharpCurve = Curves.easeOutCubic;

  /// Transición de slide estándar usada en rutas (config/routes.dart).
  static Widget slideTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    final tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: sharpCurve),
    );
    return SlideTransition(position: animation.drive(tween), child: child);
  }

  /// Transición de fade estándar (usada por ejemplo en Splash -> Login).
  static Widget fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}
