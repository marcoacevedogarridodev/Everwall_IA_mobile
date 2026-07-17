/// Constantes técnicas de bajo nivel (regex, límites) usadas por
/// utils/validators.dart y formularios en general.
class ValidationConstants {
  ValidationConstants._();

  static final RegExp emailRegex =
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  /// Al menos 8 caracteres, 1 mayúscula, 1 número, 1 caracter especial.
  static final RegExp passwordRegex =
      RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$&*~._%\-+]).{8,}$');

  static const int passwordMinLength = 8;
  static const int nameMinLength = 2;
  static const int nameMaxLength = 50;
}
