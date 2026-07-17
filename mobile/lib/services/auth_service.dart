import '../models/user_model.dart';
import 'api_service.dart';

/// Mapea 1:1 los endpoints de auth reales del backend Django:
///
///   POST /auth/register/
///   POST /auth/login/
///   POST /auth/google/
///   POST /auth/logout/
///   POST /auth/token/refresh/      (usado internamente por ApiService)
///   GET  /auth/me/
///   POST /auth/verify-email/
///   POST /auth/resend-verification/
///   POST /auth/password-reset/
///   POST /auth/password-reset/confirm/
///   POST /auth/change-password/
///
/// NOTA: los nombres exactos de los campos del body (ej. `password2` vs
/// `confirm_password`, `refresh` vs `refresh_token`) son la convención
/// más común en DRF + SimpleJWT. Si tu backend usa otros nombres, ajusta
/// aquí — es el único lugar que lo necesita.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _api = ApiService.instance;

  Future<Map<String, dynamic>> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final data = await _api.post('/auth/register/', data: {
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'password': password,
    });
    return data as Map<String, dynamic>;
  }

  /// Retorna { accessToken, refreshToken, user }
  Future<({String accessToken, String refreshToken, UserModel user})> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post('/auth/login/', data: {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;

    return _parseAuthResponse(data);
  }

  Future<({String accessToken, String refreshToken, UserModel user})>
      googleLogin(String idToken) async {
    final data = await _api.post('/auth/google/', data: {
      'id_token': idToken,
    }) as Map<String, dynamic>;

    return _parseAuthResponse(data);
  }

  Future<void> logout(String refreshToken) async {
    await _api.post('/auth/logout/', data: {'refresh': refreshToken});
  }

  Future<UserModel> me() async {
    final data = await _api.get('/auth/me/') as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<void> verifyEmail(String token) async {
    await _api.post('/auth/verify-email/', data: {'token': token});
  }

  Future<void> resendVerification(String email) async {
    await _api.post('/auth/resend-verification/', data: {'email': email});
  }

  Future<void> passwordReset(String email) async {
    await _api.post('/auth/password-reset/', data: {'email': email});
  }

  Future<void> passwordResetConfirm({
    required String token,
    required String newPassword,
  }) async {
    await _api.post('/auth/password-reset/confirm/', data: {
      'token': token,
      'password': newPassword,
    });
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _api.post('/auth/change-password/', data: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  ({String accessToken, String refreshToken, UserModel user})
      _parseAuthResponse(Map<String, dynamic> data) {
    // Soporta las 2 convenciones más comunes de SimpleJWT:
    // { access, refresh, user: {...} }  o  { tokens: { access, refresh }, user: {...} }
    final tokens = data['tokens'] as Map<String, dynamic>? ?? data;
    final access = tokens['access'] as String? ?? tokens['access_token'] as String?;
    final refresh = tokens['refresh'] as String? ?? tokens['refresh_token'] as String?;
    final userJson = data['user'] as Map<String, dynamic>?;

    if (access == null || refresh == null || userJson == null) {
      throw StateError(
        'Respuesta de login con formato inesperado. Ajusta AuthService._parseAuthResponse '
        'según el JSON real que devuelve tu backend: $data',
      );
    }

    return (
      accessToken: access,
      refreshToken: refresh,
      user: UserModel.fromJson(userJson),
    );
  }
}
