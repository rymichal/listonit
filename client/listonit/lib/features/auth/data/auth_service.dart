import 'package:dio/dio.dart';

import '../domain/user.dart';
import 'auth_api.dart';
import 'token_storage.dart';

class AuthService {
  final AuthApi _api;
  final TokenStorage _tokenStorage;

  AuthService({
    AuthApi? api,
    TokenStorage? tokenStorage,
  })  : _api = api ?? AuthApi(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final tokens = await _api.login(email: email, password: password);
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return await _api.getMe(tokens.accessToken);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<User> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await _api.register(email: email, password: password, name: name);
      return await login(email: email, password: password);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }

  Future<String?> getAccessToken() async {
    return await _tokenStorage.getAccessToken();
  }

  Future<bool> isAuthenticated() async {
    return await _tokenStorage.hasTokens();
  }

  Future<User?> getCurrentUser() async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken == null) return null;

    try {
      return await _api.getMe(accessToken);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          final newToken = await _tokenStorage.getAccessToken();
          if (newToken != null) {
            return await _api.getMe(newToken);
          }
        }
        await logout();
      }
      return null;
    }
  }

  Future<bool> refreshToken() async {
    final refresh = await _tokenStorage.getRefreshToken();
    if (refresh == null) return false;

    try {
      final tokens = await _api.refreshToken(refresh);
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return true;
    } on DioException {
      return false;
    }
  }

  AuthException _mapDioException(DioException e) {
    if (e.response?.statusCode == 401) {
      return const AuthException('Invalid email or password');
    }
    if (e.response?.statusCode == 400) {
      final detail = e.response?.data['detail'];
      if (detail != null) {
        return AuthException(detail.toString());
      }
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const AuthException('Unable to connect to server');
    }
    return AuthException(e.message ?? 'An error occurred');
  }
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}
