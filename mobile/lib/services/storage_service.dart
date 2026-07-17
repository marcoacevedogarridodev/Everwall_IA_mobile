import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

/// Capa de almacenamiento local.
///
/// - Tokens (access/refresh): flutter_secure_storage (encriptado, Keychain/Keystore).
/// - Datos no sensibles (user data cacheado, flags): SharedPreferences.
///
/// Sprint 9 extenderá esto con Hive para cache de grid/offline queue.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final _secureStorage = const FlutterSecureStorage();

  // --- Tokens ---

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(
      key: AppConstants.keyAccessToken,
      value: accessToken,
    );
    await _secureStorage.write(
      key: AppConstants.keyRefreshToken,
      value: refreshToken,
    );
  }

  Future<String?> getAccessToken() =>
      _secureStorage.read(key: AppConstants.keyAccessToken);

  Future<String?> getRefreshToken() =>
      _secureStorage.read(key: AppConstants.keyRefreshToken);

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: AppConstants.keyAccessToken);
    await _secureStorage.delete(key: AppConstants.keyRefreshToken);
  }

  // --- Usuario cacheado ---

  Future<void> saveUserJson(Map<String, dynamic> userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserData, jsonEncode(userJson));
  }

  Future<Map<String, dynamic>?> getUserJson() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyUserData);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clearUserJson() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyUserData);
  }

  /// Limpia toda la sesión (usado en logout).
  Future<void> clearSession() async {
    await clearTokens();
    await clearUserJson();
  }
}
