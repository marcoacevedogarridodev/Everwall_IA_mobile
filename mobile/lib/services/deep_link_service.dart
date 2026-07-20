import 'dart:async';
import 'package:app_links/app_links.dart';
import '../config/routes.dart';
import 'pixel_service.dart';

/// Deep links (spec 12.3): esquema `pixelapp://pixel/{id}`, ya usado por
/// el botón "Compartir" en `PixelActionsWidget`. Este servicio escucha
/// links entrantes (app en background/foreground) y el link "frío" con el
/// que la app pudo haber sido abierta, resuelve el ID contra
/// `PixelService.getPixelById()` (reutiliza `search_pixel`, no inventa
/// endpoint nuevo) y navega a `PixelDetailScreen`.
///
/// ⚠️ Configuración nativa pendiente (no soy yo quien puede generarla —
/// requiere `android/` e `ios/`, ver README "Paso 0"): hay que registrar
/// el esquema `pixelapp://` en `AndroidManifest.xml` (intent-filter) y en
/// `Info.plist` (CFBundleURLTypes). El código Dart de acá ya está listo
/// para cuando esos archivos existan — ver instrucciones exactas en el
/// README, sección Sprint 9.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  /// Si llega un link antes de que el usuario esté autenticado (ej. app
  /// recién abierta desde frío), se guarda acá y se consume después,
  /// llamando a `consumePendingLink()` desde MainScreen una vez hay
  /// sesión activa.
  String? _pendingPixelId;

  Future<void> init() async {
    try {
      // Link "frío": la app se abrió directamente desde un link.
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleUri(initialUri);

      // Links mientras la app ya está corriendo (foreground/background).
      _subscription ??= _appLinks.uriLinkStream.listen(
        _handleUri,
        onError: (_) {
          // Ignorar errores del stream — no debe tumbar la app.
        },
      );
    } catch (_) {
      // app_links puede fallar si la config nativa (intent-filter /
      // Info.plist) todavía no está — no rompemos la app por esto.
    }
  }

  void _handleUri(Uri uri) {
    if (uri.scheme != 'pixelapp' || uri.host != 'pixel') return;
    if (uri.pathSegments.isEmpty) return;
    final id = uri.pathSegments.first;
    if (id.isEmpty) return;

    _pendingPixelId = id;
    _tryConsumePending();
  }

  /// Llamar desde MainScreen.initState() (ya hay sesión activa) por si
  /// llegó un link antes de que el Navigator estuviera listo.
  void consumePendingLink() => _tryConsumePending();

  Future<void> _tryConsumePending() async {
    final id = _pendingPixelId;
    final navigator = AppRoutes.navigatorKey.currentState;
    if (id == null || navigator == null) return;

    _pendingPixelId = null;

    try {
      final pixel = await PixelService.instance.getPixelById(id);
      if (pixel != null) {
        navigator.pushNamed(AppRoutes.pixelDetail, arguments: pixel);
      }
    } catch (_) {
      // Si falla (ej. sin sesión todavía, o el píxel no existe), se
      // pierde el link silenciosamente — no es crítico para el flujo
      // principal de la app.
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
