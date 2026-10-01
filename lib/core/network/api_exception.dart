class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final List<dynamic>? details;

  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  bool get isNetworkError => statusCode == null;
  bool get isNotFound => statusCode == 404;
  bool get isValidation => statusCode == 400 || statusCode == 422;
  bool get isAuth => statusCode == 401 || statusCode == 403;

  @override
  String toString() => 'ApiException(status: $statusCode, code: $code, message: $message)';
}
