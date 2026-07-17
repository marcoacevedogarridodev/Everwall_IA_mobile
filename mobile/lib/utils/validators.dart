import 'constants.dart';

/// Validadores puros para formularios (login, registro, edición de perfil).
/// Cada método retorna `null` si es válido o un mensaje de error si no.
class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es obligatorio';
    }
    if (!ValidationConstants.emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < ValidationConstants.passwordMinLength) {
      return 'Debe tener al menos ${ValidationConstants.passwordMinLength} caracteres';
    }
    return null;
  }

  /// Validación estricta (spec: 8+ chars, 1 mayúscula, 1 número, 1 especial),
  /// usada en Register/Reset Password (Sprint 2).
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (!ValidationConstants.passwordRegex.hasMatch(value)) {
      return 'Debe tener 8+ caracteres, 1 mayúscula, 1 número y 1 especial';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != original) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  static String? requiredField(String? value, {String field = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field es obligatorio';
    }
    return null;
  }

  static String? name(String? value, {String field = 'El nombre'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field es obligatorio';
    }
    if (value.trim().length < ValidationConstants.nameMinLength) {
      return '$field es muy corto';
    }
    return null;
  }
}
