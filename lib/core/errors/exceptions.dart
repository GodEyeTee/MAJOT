abstract class AppException implements Exception {
  const AppException(this.message, {this.code, this.cause, this.context});

  final String message;
  final String? code;
  final dynamic cause;
  final Map<String, dynamic>? context;

  @override
  String toString() => message;
}

class ServerException extends AppException {
  const ServerException([super.message = 'Server error occurred', String? code])
    : super(code: code);
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, [dynamic cause]) : super(cause: cause);

  @override
  String toString() =>
      'DatabaseException: $message${cause != null ? ' ($cause)' : ''}';
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.cause, super.context});
}

class CacheException extends AppException {
  const CacheException([super.message = 'Cache error occurred', String? code])
    : super(code: code);
}
