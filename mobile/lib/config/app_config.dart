/// Configuración de entorno de la app.
///
/// Cambia [Environment.current] o usa --dart-define para apuntar a
/// distintos backends (dev/staging/prod) sin tocar código.
///
/// Ejemplo:
/// flutter run --dart-define=API_BASE_URL=https://api.miapp.com/api
enum Environment { dev, staging, prod }

class AppConfig {
  AppConfig._();

  static const Environment current = Environment.dev;

  /// URL base del API REST. Sobreescribible por --dart-define=API_BASE_URL=...
  ///
  /// Por ahora apunta a tu backend Django local en Docker Compose
  /// (puerto 8000, el default de Django). Para que tu celular físico
  /// (conectado por USB) pueda llegar al `localhost:8000` de tu PC, corre
  /// UNA VEZ por sesión de USB (antes de `flutter run`, o mientras corre):
  ///   adb reverse tcp:8000 tcp:8000
  /// Esto redirige el localhost del celular hacia el de tu PC a través
  /// del cable — más confiable que usar la IP de WiFi.
  ///
  /// Si tu docker-compose expone Django en otro puerto, cambia el 8000 de
  /// abajo Y el del comando `adb reverse` para que coincidan.
  ///
  /// Cuando despliegues el backend de verdad, cambia esto por tu dominio,
  /// o pásalo sin tocar código:
  ///   flutter run --dart-define=API_BASE_URL=https://api.tudominio.com/api
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  /// URL base del servidor WebSocket (chat en tiempo real, Sprint 6).
  /// Mismo esquema que apiBaseUrl: local vía adb reverse por ahora.
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://localhost:8000/ws',
  );

  /// Clave pública de Stripe (Sprint 4).
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_replace_me',
  );

  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;

  static bool get isProd => current == Environment.prod;
  static bool get isDev => current == Environment.dev;
}
