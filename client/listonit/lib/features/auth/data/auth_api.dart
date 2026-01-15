import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../domain/user.dart';

class AuthApi {
  final Dio _dio;

  AuthApi({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    return Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  Future<({String accessToken, String refreshToken})> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: FormData.fromMap({
        'username': username,
        'password': password,
      }),
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    return (
      accessToken: response.data['access_token'] as String,
      refreshToken: response.data['refresh_token'] as String,
    );
  }

  Future<({String accessToken, String refreshToken})> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );

    return (
      accessToken: response.data['access_token'] as String,
      refreshToken: response.data['refresh_token'] as String,
    );
  }

  Future<User> getMe(String accessToken) async {
    final response = await _dio.get(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );

    return User.fromJson(response.data);
  }
}
