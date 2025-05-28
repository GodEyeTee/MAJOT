import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class SignInWithGoogleEvent extends AuthEvent {}

class SignOutEvent extends AuthEvent {}

class AuthStateChangedEvent extends AuthEvent {
  final User? user;
  final Failure? failure;

  const AuthStateChangedEvent({this.user, this.failure});

  @override
  List<Object?> get props => [user, failure];
}
