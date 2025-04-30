abstract class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

class ServerException extends AppException {
  const ServerException([super.message = 'Server error occurred']);
}

class DatabaseException extends AppException {
  final dynamic cause;

  const DatabaseException(super.message, [this.cause]);

  @override
  String toString() =>
      'DatabaseException: $message${cause != null ? ' ($cause)' : ''}';
}

class AuthException extends AppException {
  const AuthException([super.message = 'Authentication error occurred']);
}

class CacheException extends AppException {
  const CacheException([super.message = 'Cache error occurred']);
}
