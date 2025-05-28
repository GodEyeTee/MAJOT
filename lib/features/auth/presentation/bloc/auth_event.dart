import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';

/// Base authentication event with security metadata
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Initial authentication status check event
class CheckAuthStatusEvent extends AuthEvent {
  final bool forceRefresh;
  final String? source;

  const CheckAuthStatusEvent({this.forceRefresh = false, this.source});

  @override
  List<Object?> get props => [forceRefresh, source];
}

/// Google Sign-In event with security context
class SignInWithGoogleEvent extends AuthEvent {
  final String? deviceId;
  final String? ipAddress;
  final Map<String, dynamic>? securityContext;

  const SignInWithGoogleEvent({
    this.deviceId,
    this.ipAddress,
    this.securityContext,
  });

  @override
  List<Object?> get props => [deviceId, ipAddress, securityContext];
}

/// Sign out event with cleanup options
class SignOutEvent extends AuthEvent {
  final bool clearCache;
  final bool revokeTokens;
  final String? reason;

  const SignOutEvent({
    this.clearCache = true,
    this.revokeTokens = true,
    this.reason,
  });

  @override
  List<Object?> get props => [clearCache, revokeTokens, reason];
}

/// Internal authentication state change event
class AuthStateChangedEvent extends AuthEvent {
  final User? user;
  final Failure? failure;
  final DateTime timestamp;
  final String? changeSource;

  AuthStateChangedEvent({
    this.user,
    this.failure,
    DateTime? timestamp,
    this.changeSource,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [user, failure, timestamp, changeSource];
}

/// Session validation event for periodic security checks
class ValidateSessionEvent extends AuthEvent {
  final bool isPeriodicCheck;
  final Duration? sessionDuration;

  const ValidateSessionEvent({
    this.isPeriodicCheck = true,
    this.sessionDuration,
  });

  @override
  List<Object?> get props => [isPeriodicCheck, sessionDuration];
}

/// Refresh user data event for updated permissions/profile
class RefreshUserDataEvent extends AuthEvent {
  final bool includePermissions;
  final List<String>? specificFields;

  const RefreshUserDataEvent({
    this.includePermissions = true,
    this.specificFields,
  });

  @override
  List<Object?> get props => [includePermissions, specificFields];
}

/// Security alert event for suspicious activities
class SecurityAlertEvent extends AuthEvent {
  final String alertType;
  final String description;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  SecurityAlertEvent({
    required this.alertType,
    required this.description,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [alertType, description, metadata, timestamp];
}

/// Biometric authentication event (for future implementation)
class BiometricAuthEvent extends AuthEvent {
  final String biometricType;
  final bool fallbackToPassword;

  const BiometricAuthEvent({
    required this.biometricType,
    this.fallbackToPassword = true,
  });

  @override
  List<Object?> get props => [biometricType, fallbackToPassword];
}
