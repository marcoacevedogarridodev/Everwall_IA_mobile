/// Rutas a los assets estáticos de la app.
///
/// `logo.png` ya es un archivo real (assets/images/logo.png) y está
/// declarado en la sección `assets:` del pubspec.yaml. Los demás (Lottie,
/// splash background) siguen siendo placeholders — agrégalos y regístralos
/// en pubspec.yaml antes de usarlos con Image.asset/Lottie.asset.
class Assets {
  Assets._();

  static const String logo = 'assets/images/logo.png';
  static const String icon = 'assets/images/icon.png';
  static const String logoAnimated = 'assets/images/logo_animated.json';
  static const String splashBackground = 'assets/images/splash_background.png';
  static const String loadingAnimation = 'assets/animations/loading_animation.json';
}
