import 'package:equatable/equatable.dart';
import '../../domain/entities/security_settings.dart';

abstract class SecurityState extends Equatable {
  const SecurityState();

  @override
  List<Object> get props => [];
}

class SecurityInitial extends SecurityState {}

class SecurityLoading extends SecurityState {}

class SecurityLoaded extends SecurityState {
  final SecuritySettings settings;

  const SecurityLoaded(this.settings);

  @override
  List<Object> get props => [settings];
}

class SecurityError extends SecurityState {
  final String message;

  const SecurityError(this.message);

  @override
  List<Object> get props => [message];
}
