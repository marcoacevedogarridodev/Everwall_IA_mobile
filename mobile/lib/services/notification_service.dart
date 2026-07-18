import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_exception.dart';
import 'api_service.dart';

/// Notificaciones push vía Firebase Cloud Messaging (spec 12.1: nuevo
/// like, nuevo comentario, mensaje privado, confirmación de compra).
///
/// ⚠️ REQUIERE CONFIGURACIÓN MANUAL antes de funcionar de verdad — no es
/// algo que se pueda dejar 100% listo sin tus credenciales de Firebase:
///   1. `flutter create .` (ver README, Paso 0) para tener android/ e ios/.
///   2. Crear un proyecto en https://console.firebase.google.com
///   3. Correr `flutterfire configure` en la raíz de `mobile/` — esto
///      genera `lib/firebase_options.dart`, `android/app/google-services.json`
///      y `ios/Runner/GoogleService-Info.plist`.
///   4. Descomentar la inicialización en `main.dart` (ver comentarios ahí).
///
/// Mientras eso no esté hecho, `init()` falla en silencio (try/catch) y la
/// app sigue funcionando 100% normal sin push — no rompe nada.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      if (granted) {
        final token = await messaging.getToken();
        if (token != null) await _registerDeviceToken(token);
        messaging.onTokenRefresh.listen(_registerDeviceToken);
      }

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      _initialized = true;
    } catch (_) {
      // Firebase no está configurado todavía (faltan firebase_options.dart /
      // google-services.json / GoogleService-Info.plist) — no rompemos la
      // app por esto, simplemente no hay push hasta que se complete el setup.
    }
  }

  /// POST /auth/register_device/ — endpoint PROPUESTO, no estaba en tu
  /// lista de rutas. Ver PENDING_BACKEND_ENDPOINTS.md.
  Future<void> _registerDeviceToken(String token) async {
    try {
      await ApiService.instance.post('/auth/register_device/', data: {
        'fcm_token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
    } on ApiException {
      // Endpoint aún no existe en el backend — se ignora, no es crítico.
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // TODO: mostrar un in-app banner/snackbar con message.notification?.title
    // y message.notification?.body. Se deja como hook simple por ahora;
    // cuando definamos el diseño de notificación in-app lo conectamos acá.
  }
}

/// Handler de mensajes en background/terminado. DEBE ser una función
/// top-level (no un método de clase) por requisito de firebase_messaging.
/// Regístralo en main.dart con `FirebaseMessaging.onBackgroundMessage(...)`
/// (ya está ahí, comentado hasta que Firebase esté configurado).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Nada más por ahora — cuando haya UI de notificaciones locales
  // (flutter_local_notifications) se dispara acá para mensajes silenciosos.
}
