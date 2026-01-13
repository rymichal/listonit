import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../features/auth/data/token_storage.dart';
import '../../features/auth/data/auth_api.dart';

class AuthInterceptor extends QueuedInterceptor {
  final TokenStorage _tokenStorage;
  final AuthApi _authApi;
  final void Function()? onAuthFailure;

  bool _isRefreshing = false;

  AuthInterceptor({
    TokenStorage? tokenStorage,
    AuthApi? authApi,
    this.onAuthFailure,
  })  : _tokenStorage = tokenStorage ?? TokenStorage(),
        _authApi = authApi ?? AuthApi();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for auth endpoints
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/register') ||
        options.path.contains('/auth/refresh')) {
      return handler.next(options);
    }

    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Skip refresh for auth endpoints
    if (err.requestOptions.path.contains('/auth/')) {
      return handler.next(err);
    }

    if (_isRefreshing) {
      return handler.next(err);
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        _handleAuthFailure();
        return handler.next(err);
      }

      developer.log('Attempting token refresh...');
      final tokens = await _authApi.refreshToken(refreshToken);
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      developer.log('Token refresh successful');

      // Retry the original request with new token
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer ${tokens.accessToken}';

      final response = await Dio().fetch(opts);
      return handler.resolve(response);
    } on DioException catch (e) {
      developer.log('Token refresh failed: ${e.message}');
      _handleAuthFailure();
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  void _handleAuthFailure() {
    _tokenStorage.clearTokens();
    onAuthFailure?.call();
  }
}
