import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { unknown, authenticating, authenticated, unauthenticated }

/// Estado global de autenticación. `main.dart` lo registra en el
/// MultiProvider; las screens lo consumen vía `context.watch<AuthProvider>()`
/// o `context.read<AuthProvider>()` para acciones puntuales.
class AuthProvider extends ChangeNotifier {
  final _authService = AuthService.instance;
  final _storage = StorageService.instance;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Llamado una vez al iniciar la app (ver splash_screen.dart) para
  /// decidir si navegar a Login o directo a Main con la sesión guardada.
  Future<void> checkAuthStatus() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final user = await _authService.me();
      _user = user;
      _status = AuthStatus.authenticated;
    } catch (_) {
      await _storage.clearSession();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final result = await _authService.login(email: email, password: password);
      await _storage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      await _storage.saveUserJson(result.user.toJson());
      _user = result.user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Retorna true si el registro fue exitoso (backend debería enviar el
  /// email de verificación automáticamente).
  /// Requiere el idToken real obtenido con el paquete `google_sign_in`
  /// (pendiente de integrar en la UI, ver TODO en login_screen.dart).
  Future<bool> googleLogin(String idToken) async {
    _setLoading(true);
    try {
      final result = await _authService.googleLogin(idToken);
      await _storage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      await _storage.saveUserJson(result.user.toJson());
      _user = result.user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _authService.register(
        email: email,
        firstName: firstName,
        lastName: lastName,
        password: password,
      );
      _errorMessage = null;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resendVerification(String email) => _runVoidAction(
        () => _authService.resendVerification(email),
      );

  /// A diferencia de las otras acciones, esta relanza la excepción (en vez
  /// de solo retornar bool) porque VerifyEmailScreen necesita distinguir
  /// "token inválido" con su propio try/catch local.
  Future<void> confirmEmailToken(String token) async {
    _setLoading(true);
    try {
      await _authService.verifyEmail(token);
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> requestPasswordReset(String email) => _runVoidAction(
        () => _authService.passwordReset(email),
      );

  Future<bool> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) =>
      _runVoidAction(
        () => _authService.passwordResetConfirm(
          token: token,
          newPassword: newPassword,
        ),
      );

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) =>
      _runVoidAction(
        () => _authService.changePassword(
          oldPassword: oldPassword,
          newPassword: newPassword,
        ),
      );

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    _setLoading(true);
    try {
      final updated = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
      );
      _user = updated;
      await _storage.saveUserJson(updated.toJson());
      _errorMessage = null;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();
    try {
      if (refreshToken != null) {
        await _authService.logout(refreshToken);
      }
    } catch (_) {
      // Si falla el logout remoto igual limpiamos la sesión local.
    }
    await _storage.clearSession();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runVoidAction(Future<void> Function() action) async {
    _setLoading(true);
    try {
      await action();
      _errorMessage = null;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
