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
  /// IMPORTANTE: aún no tenemos el dominio real del backend (solo se
  /// compartieron las rutas relativas de Django, ej. api/auth/login/).
  /// Reemplaza el valor de abajo por tu dominio real, por ejemplo:
  ///   'https://api.pixelapp.com/api'   (producción)
  ///   'http://10.0.2.2:8000/api'       (Django local + emulador Android)
  ///   'http://localhost:8000/api'      (Django local + iOS simulator/web)
  /// o pásalo sin tocar código:
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://tu-api.com/api',
  );

  /// URL base del servidor WebSocket (chat en tiempo real, Sprint 6).
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://tu-api.com/ws',
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
