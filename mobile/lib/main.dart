import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/grid_provider.dart';
import 'providers/pixel_provider.dart';
import 'providers/theme_provider.dart';
import 'services/deep_link_service.dart';
import 'services/offline_service.dart';
// Sprint 8 (push notifications) — descomenta tras correr
// `flutterfire configure` (ver README y notification_service.dart):
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'firebase_options.dart';
// import 'services/notification_service.dart';

/// Punto de entrada.
Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Mantiene visible el splash NATIVO (el mismo que ya se ve al tocar el
  // ícono de la app, configurado en pubspec.yaml -> flutter_native_splash)
  // hasta que llamemos a FlutterNativeSplash.remove() manualmente desde
  // SplashScreen, una vez terminó checkAuthStatus(). Así NUNCA se ven dos
  // splashes distintos (nativo + uno propio de Flutter) — solo existe el
  // nativo, que se queda el tiempo justo y necesario, y desaparece
  // revelando directamente Login o Main.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Stripe (spec 8.2, Sprint 4): requiere AppConfig.stripePublishableKey
  // con tu clave pública real. Con el placeholder por defecto el SDK se
  // inicializa igual (no rompe el build) pero cualquier pago fallará.
  //
  // ⚠️ Solo en mobile (iOS/Android): el setter `Stripe.publishableKey`
  // llama internamente a `dart:io Platform.operatingSystem`, que no existe
  // en la web y tira `Unsupported operation` al cargar la app en Chrome.
  // El soporte de Stripe para Flutter Web existe pero requiere agregar
  // el script de Stripe.js a `web/index.html` y usar una config aparte —
  // no está en el alcance de este sprint. Mientras tanto, en web el flujo
  // de compra (PixelPaymentScreen) no va a poder cobrar de verdad; el
  // resto de la app (auth, grid, chat, comentarios, etc.) funciona igual.
  //
  // ⚠️ En Android, requiere que MainActivity extienda
  // FlutterFragmentActivity (no FlutterActivity) — ver
  // android/app/src/main/kotlin/.../MainActivity.kt y el README. El
  // try/catch de acá es una red de seguridad: si esto falla por cualquier
  // razón (falta ese cambio nativo, red, etc.), la app igual arranca en
  // vez de quedarse colgada antes de runApp().
  if (!kIsWeb) {
    try {
      Stripe.publishableKey = AppConfig.stripePublishableKey;
      await Stripe.instance.applySettings();
    } catch (_) {
      // El flujo de compra (PixelPaymentScreen) fallará hasta que se
      // resuelva la causa real, pero el resto de la app sigue funcionando.
    }
  }

  // Firebase / Push notifications (Sprint 8, spec 12.1). Descomenta estas
  // 3 líneas después de:
  //   1. flutter create . (ver README, Paso 0)
  //   2. flutterfire configure (genera firebase_options.dart + configs nativas)
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Offline support (Sprint 9, spec 12.2): abre las cajas de Hive para
  // cache de grid + cola de acciones pendientes. Seguro de llamar siempre
  // (try/catch interno) — si Hive no puede inicializar en alguna
  // plataforma, la app sigue 100% funcional, solo sin cache offline.
  await OfflineService.instance.init();

  // Deep links (Sprint 9, spec 12.3): empieza a escuchar
  // pixelapp://pixel/{id}. La navegación real ocurre una vez hay sesión
  // activa (ver MainScreen.initState -> consumePendingLink()).
  DeepLinkService.instance.init();

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