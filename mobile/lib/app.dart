import 'package:flutter/material.dart';
import 'config/constants.dart';
import 'config/routes.dart';
import 'config/theme.dart';

/// Widget raíz de la app. Configura MaterialApp con el tema global,
/// las rutas nombradas y la ruta inicial (Splash).
class PixelApp extends StatelessWidget {
  const PixelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
