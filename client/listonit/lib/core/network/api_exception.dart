class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  bool get isNetworkError => statusCode == null;
  bool get isNotFound => statusCode == 404;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class NetworkException extends ApiException {
  NetworkException({super.message = 'Network error. Please check your connection.'});
}
