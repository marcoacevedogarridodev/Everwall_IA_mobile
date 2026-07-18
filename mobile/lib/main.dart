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
// Sprint 8 (push notifications) — descomenta tras correr
// `flutterfire configure` (ver README y notification_service.dart):
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'firebase_options.dart';
// import 'services/notification_service.dart';

/// Punto de entrada.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Stripe (spec 8.2, Sprint 4): requiere AppConfig.stripePublishableKey
  // con tu clave pública real. Con el placeholder por defecto el SDK se
  // inicializa igual (no rompe el build) pero cualquier pago fallará.
  Stripe.publishableKey = AppConfig.stripePublishableKey;
  await Stripe.instance.applySettings();

  // Firebase / Push notifications (Sprint 8, spec 12.1). Descomenta estas
  // 3 líneas después de:
  //   1. flutter create . (ver README, Paso 0)
  //   2. flutterfire configure (genera firebase_options.dart + configs nativas)
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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
