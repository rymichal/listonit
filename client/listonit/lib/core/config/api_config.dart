import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  /// Base URL from env (e.g., http://localhost:8000)
  static String get _baseUrlFromEnv =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  /// Base URL for REST API (e.g., http://localhost:8000/api/v1)
  static String get baseUrl => '$_baseUrlFromEnv/api/v1';

  /// Base URL for WebSocket (e.g., ws://localhost:8000/api/v1)
  static String get wsBaseUrl {
    final apiBase = _baseUrlFromEnv;
    // Convert http/https to ws/wss
    if (apiBase.startsWith('https://')) {
      return apiBase.replaceFirst('https://', 'wss://') + '/api/v1';
    } else if (apiBase.startsWith('http://')) {
      return apiBase.replaceFirst('http://', 'ws://') + '/api/v1';
    }
    return apiBase + '/api/v1';
  }
}
