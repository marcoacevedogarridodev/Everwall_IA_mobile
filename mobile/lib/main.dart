import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/grid_provider.dart';
import 'providers/pixel_provider.dart';
import 'providers/theme_provider.dart';

/// Punto de entrada. A partir del Sprint 6 aquí se agrega ChatProvider.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GridProvider()),
        ChangeNotifierProvider(create: (_) => PixelProvider()),
        // Sprint 6: ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const PixelApp(),
    ),
  );
}
