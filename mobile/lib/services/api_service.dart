import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'api_exception.dart';
import 'storage_service.dart';

/// Cliente HTTP central (Dio) usado por TODOS los services (auth, pixel,
/// payment, etc.). Centraliza:
///
/// 1. Base URL + timeouts (AppConfig).
/// 2. Interceptor de auth: agrega `Authorization: Bearer <token>` a cada
///    request si hay un access_token guardado.
/// 3. Interceptor de refresh: si una request falla con 401, intenta
///    refrescar el token una vez contra /auth/token/refresh/ y reintenta
///    la request original. Si el refresh también falla, limpia la sesión
///    y propaga el error (AuthProvider debe escuchar esto y deslogear).
/// 4. Logging solo en modo dev.
/// 5. Traducción de DioException -> ApiException con mensaje legible.
class ApiService {
  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeoutMs),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.instance.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isRefreshCall = error.requestOptions.path.contains('token/refresh');

          if (isUnauthorized && !isRefreshCall) {
            final refreshed = await _tryRefreshToken();
            if (refreshed != null) {
              final retryOptions = error.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $refreshed';
              try {
                final response = await _dio.fetch(retryOptions);
                return handler.resolve(response);
              } catch (_) {
                // sigue al handler.next de abajo
              }
            } else {
              // Refresh falló: limpiar sesión. AuthProvider debe reaccionar
              // a esto redirigiendo a Login (ver AuthProvider.logout()).
              await StorageService.instance.clearSession();
            }
          }
          handler.next(error);
        },
      ),
    );

    if (AppConfig.isDev) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  static final ApiService instance = ApiService._internal();
  late final Dio _dio;

  /// Evita refrescar el token en paralelo si varias requests fallan a la vez.
  Future<String>? _refreshFuture;

  Future<String?> _tryRefreshToken() async {
    _refreshFuture ??= _performRefresh();
    try {
      final token = await _refreshFuture;
      return token;
    } catch (_) {
      return null;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<String> _performRefresh() async {
    final refreshToken = await StorageService.instance.getRefreshToken();
    if (refreshToken == null) {
      throw ApiException('No hay refresh token disponible');
    }

    final response = await _dio.post(
      '/auth/token/refresh/',
      data: {'refresh': refreshToken},
      options: Options(headers: {'Authorization': null}),
    );

    final newAccess = response.data['access'] as String?;
    if (newAccess == null) {
      throw ApiException('Respuesta de refresh inválida');
    }

    final newRefresh = response.data['refresh'] as String? ?? refreshToken;
    await StorageService.instance.saveTokens(
      accessToken: newAccess,
      refreshToken: newRefresh,
    );

    return newAccess;
  }

  // --- Métodos HTTP genéricos ---

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get(endpoint, queryParameters: query);
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> post(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> put(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> patch(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.patch(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> delete(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.delete(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Para multipart (subida de imágenes de píxeles, Sprint 4).
  Future<dynamic> multipart(String endpoint, FormData data) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    // DRF suele devolver { "detail": "..." } o { "field": ["error"] }
    String message = 'Ocurrió un error. Intenta nuevamente.';
    Map<String, dynamic>? errors;

    if (data is Map<String, dynamic>) {
      if (data['detail'] != null) {
        message = data['detail'].toString();
      } else if (data.isNotEmpty) {
        errors = data;
        final firstKey = data.keys.first;
        final firstVal = data[firstKey];
        final firstMsg = firstVal is List ? firstVal.first : firstVal;
        message = '$firstMsg';
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Tiempo de espera agotado. Revisa tu conexión.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No se pudo conectar al servidor.';
    }

    return ApiException(message, statusCode: statusCode, errors: errors);
  }
}
