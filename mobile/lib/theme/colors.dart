import 'package:flutter/material.dart';

/// Paleta de colores central de la app.
/// Cualquier color usado en la UI debe salir de aquí, nunca hardcodeado
/// directamente en un widget.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF5BA0F4);
  static const Color primaryDark = Color(0xFF3D7ED9);

  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF2D2D2D);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textDisabled = Color(0xFF5C5C5C);

  static const Color error = Color(0xFFFF4757);
  static const Color success = Color(0xFF2ED573);

  static const Color like = Color(0xFFFF4757);
  static const Color fire = Color(0xFFFF6B35);

  static const Color divider = Color(0xFF2A2A2A);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
