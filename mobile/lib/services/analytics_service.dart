import 'package:firebase_analytics/firebase_analytics.dart';

/// Firebase Analytics (spec 12.4): Login/Register, Pixel view, Purchase
/// complete, Like given, Comment posted.
///
/// Mismo patrón defensivo que `NotificationService`: requiere Firebase
/// configurado (`flutterfire configure`, ver README Sprint 8) para
/// funcionar de verdad. Mientras tanto, cada llamada falla en silencio —
/// la app nunca se rompe por un evento de analytics que no se pudo
/// registrar.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  Future<void> _log(String name, [Map<String, Object>? params]) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (_) {
      // Firebase no configurado todavía, o falló la red — no es crítico.
    }
  }

  Future<void> logLogin({required String method}) =>
      _log('login', {'method': method});

  Future<void> logRegister() => _log('sign_up', {'method': 'email'});

  Future<void> logPixelView(String pixelId) =>
      _log('pixel_view', {'pixel_id': pixelId});

  Future<void> logPurchaseComplete({
    required String pixelId,
    required num amount,
    required String currency,
  }) =>
      _log('purchase_complete', {
        'pixel_id': pixelId,
        'value': amount,
        'currency': currency,
      });

  Future<void> logLikeGiven(String pixelId) =>
      _log('like_given', {'pixel_id': pixelId});

  Future<void> logCommentPosted(String pixelId) =>
      _log('comment_posted', {'pixel_id': pixelId});
}
