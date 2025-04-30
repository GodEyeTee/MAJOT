abstract class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

class ServerException extends AppException {
  const ServerException([String message = 'Server error occurred'])
    : super(message);
}

class DatabaseException extends AppException {
  final dynamic cause;

  const DatabaseException(String message, [this.cause]) : super(message);

  @override
  String toString() =>
      'DatabaseException: $message${cause != null ? ' ($cause)' : ''}';
}

class AuthException extends AppException {
  const AuthException([String message = 'Authentication error occurred'])
    : super(message);
}

class CacheException extends AppException {
  const CacheException([String message = 'Cache error occurred'])
    : super(message);
}
