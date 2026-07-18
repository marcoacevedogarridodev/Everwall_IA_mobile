/// Constantes de producto/negocio (no confundir con utils/constants.dart,
/// que guarda constantes puramente técnicas como regex).
class AppConstants {
  AppConstants._();

  static const String appName = 'Pixel App';

  // Almacenamiento local (keys)
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserData = 'user_data';
  static const String keyThemeMode = 'theme_mode';
  static const String keyOnboardingSeen = 'onboarding_seen';
  static const String keyNotificationsEnabled = 'notifications_enabled';

  // Reglas de negocio
  static const int ownerMessageMaxLength = 140;
  static const int fireThresholdLikes = 50;
  static const List<String> supportedCurrencies = ['USD', 'CLP', 'EUR'];

  // Grid
  static const double gridCellRadius = 8.0;
  static const double gridCellSpacing = 4.0;

  // Paginación
  static const int defaultPageSize = 30;
}
