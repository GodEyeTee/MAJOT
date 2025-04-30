import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server failure occurred'])
    : super(message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([String message = 'Database failure occurred'])
    : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure([String message = 'Authentication failure occurred'])
    : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache failure occurred'])
    : super(message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'Unknown failure occurred'])
    : super(message);
}
