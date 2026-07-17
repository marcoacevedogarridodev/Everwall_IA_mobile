/// Rutas a los assets estáticos de la app.
///
/// IMPORTANTE: estos archivos aún NO existen en el repo (assets/images,
/// assets/animations están vacíos salvo .gitkeep). Agrega los binarios
/// reales y descomenta la sección `assets:` en pubspec.yaml antes de
/// usar estas constantes con Image.asset / Lottie.asset, o la app
/// lanzará una excepción "Unable to load asset" al intentar cargarlos.
class Assets {
  Assets._();

  static const String logo = 'assets/images/logo.png';
  static const String logoAnimated = 'assets/images/logo_animated.json';
  static const String splashBackground = 'assets/images/splash_background.png';
  static const String loadingAnimation = 'assets/animations/loading_animation.json';
}
