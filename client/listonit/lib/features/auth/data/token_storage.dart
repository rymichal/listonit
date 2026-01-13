import 'dart:io' show Platform;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage? _secureStorage;
  SharedPreferences? _prefs;

  final bool _useSecureStorage;

  TokenStorage({FlutterSecureStorage? secureStorage})
      : _useSecureStorage = !Platform.isMacOS && !Platform.isWindows && !Platform.isLinux,
        _secureStorage = (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux)
            ? (secureStorage ??
                const FlutterSecureStorage(
                  aOptions: AndroidOptions(encryptedSharedPreferences: true),
                  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
                ))
            : null;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<String?> getAccessToken() async {
    if (_useSecureStorage) {
      return await _secureStorage!.read(key: _accessTokenKey);
    }
    final prefs = await _getPrefs();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    if (_useSecureStorage) {
      return await _secureStorage!.read(key: _refreshTokenKey);
    }
    final prefs = await _getPrefs();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (_useSecureStorage) {
      await Future.wait([
        _secureStorage!.write(key: _accessTokenKey, value: accessToken),
        _secureStorage!.write(key: _refreshTokenKey, value: refreshToken),
      ]);
    } else {
      final prefs = await _getPrefs();
      await Future.wait([
        prefs.setString(_accessTokenKey, accessToken),
        prefs.setString(_refreshTokenKey, refreshToken),
      ]);
    }
  }

  Future<void> clearTokens() async {
    if (_useSecureStorage) {
      await Future.wait([
        _secureStorage!.delete(key: _accessTokenKey),
        _secureStorage!.delete(key: _refreshTokenKey),
      ]);
    } else {
      final prefs = await _getPrefs();
      await Future.wait([
        prefs.remove(_accessTokenKey),
        prefs.remove(_refreshTokenKey),
      ]);
    }
  }

  Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}
