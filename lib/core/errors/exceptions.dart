abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic cause;
  final Map<String, dynamic>? context;

  const AppException(this.message, {this.code, this.cause, this.context});

  @override
  String toString() => message;
}

class ServerException extends AppException {
  const ServerException([
    String message = 'Server error occurred',
    String? code,
  ]) : super(message, code: code);
}

class DatabaseException extends AppException {
  const DatabaseException(String message, [dynamic cause])
    : super(message, cause: cause);

  @override
  String toString() =>
      'DatabaseException: $message${cause != null ? ' ($cause)' : ''}';
}

class AuthException extends AppException {
  const AuthException(
    String message, {
    String? code,
    dynamic cause,
    Map<String, dynamic>? context,
  }) : super(message, code: code, cause: cause, context: context);
}

class CacheException extends AppException {
  const CacheException([String message = 'Cache error occurred', String? code])
    : super(message, code: code);
}
