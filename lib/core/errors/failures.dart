import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server failure occurred']);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Database failure occurred']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failure occurred']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache failure occurred']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unknown failure occurred']);
}
