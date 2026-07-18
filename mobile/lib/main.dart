import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/grid_provider.dart';
import 'providers/pixel_provider.dart';
import 'providers/theme_provider.dart';

/// Punto de entrada.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Stripe (spec 8.2, Sprint 4): requiere AppConfig.stripePublishableKey
  // con tu clave pública real. Con el placeholder por defecto el SDK se
  // inicializa igual (no rompe el build) pero cualquier pago fallará.
  Stripe.publishableKey = AppConfig.stripePublishableKey;
  await Stripe.instance.applySettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GridProvider()),
        ChangeNotifierProvider(create: (_) => PixelProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const PixelApp(),
    ),
  );
}
