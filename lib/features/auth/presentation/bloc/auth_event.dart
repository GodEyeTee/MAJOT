// =====================================================
// AUTH EVENTS - Security-First Event Architecture
// =====================================================

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
/// Triggered on app startup and after successful authentication
class CheckAuthStatusEvent extends AuthEvent {
  final bool forceRefresh;
  final String? source; // For debugging/analytics

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
  final String? reason; // voluntary, timeout, security, etc.

  const SignOutEvent({
    this.clearCache = true,
    this.revokeTokens = true,
    this.reason,
  });

  @override
  List<Object?> get props => [clearCache, revokeTokens, reason];
}

/// Internal authentication state change event
/// Triggered by the authentication stream
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
  final String biometricType; // fingerprint, faceId, etc.
  final bool fallbackToPassword;

  const BiometricAuthEvent({
    required this.biometricType,
    this.fallbackToPassword = true,
  });

  @override
  List<Object?> get props => [biometricType, fallbackToPassword];
}

// =====================================================
// AUTH STATES - Comprehensive State Management
// =====================================================

/// Base authentication state with security context
abstract class AuthState extends Equatable {
  final DateTime timestamp;
  final String? stateId;

  AuthState({DateTime? timestamp, this.stateId})
    : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [timestamp, stateId];
}

/// Initial state before any authentication checks
class AuthInitial extends AuthState {
  AuthInitial({super.timestamp, super.stateId});
}

/// Loading state with progress indication
class AuthLoading extends AuthState {
  final String? operation; // 'signing_in', 'signing_out', 'validating', etc.
  final double? progress; // 0.0 to 1.0 for progress indication
  final String? message;

  AuthLoading({
    this.operation,
    this.progress,
    this.message,
    super.timestamp,
    super.stateId,
  });

  @override
  List<Object?> get props => [...super.props, operation, progress, message];
}

/// Authenticated state with comprehensive user context
class Authenticated extends AuthState {
  final User? user;
  final DateTime? sessionStart;
  final Duration? sessionDuration;
  final Map<String, dynamic>? securityContext;
  final List<String>? activePermissions;

  Authenticated({
    this.user,
    this.sessionStart,
    this.sessionDuration,
    this.securityContext,
    this.activePermissions,
    super.timestamp,
    super.stateId,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    user,
    sessionStart,
    sessionDuration,
    securityContext,
    activePermissions,
  ];

  /// Check if session is still valid
  bool get isSessionValid {
    if (sessionStart == null || sessionDuration == null) return true;

    final elapsed = DateTime.now().difference(sessionStart!);
    return elapsed <= sessionDuration!;
  }

  /// Get remaining session time
  Duration? get remainingSessionTime {
    if (sessionStart == null || sessionDuration == null) return null;

    final elapsed = DateTime.now().difference(sessionStart!);
    final remaining = sessionDuration! - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Create a copy with updated information
  Authenticated copyWith({
    User? user,
    DateTime? sessionStart,
    Duration? sessionDuration,
    Map<String, dynamic>? securityContext,
    List<String>? activePermissions,
    DateTime? timestamp,
    String? stateId,
  }) {
    return Authenticated(
      user: user ?? this.user,
      sessionStart: sessionStart ?? this.sessionStart,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      securityContext: securityContext ?? this.securityContext,
      activePermissions: activePermissions ?? this.activePermissions,
      timestamp: timestamp ?? this.timestamp,
      stateId: stateId ?? this.stateId,
    );
  }
}

/// Unauthenticated state with context
class Unauthenticated extends AuthState {
  final String?
  reason; // 'signed_out', 'session_expired', 'invalid_credentials', etc.
  final bool canRetry;
  final Duration? cooldownPeriod;

  Unauthenticated({
    this.reason,
    this.canRetry = true,
    this.cooldownPeriod,
    super.timestamp,
    super.stateId,
  });

  @override
  List<Object?> get props => [...super.props, reason, canRetry, cooldownPeriod];
}

/// Authentication error state with detailed error information
class AuthError extends AuthState {
  final String message;
  final String? errorCode;
  final String? errorType; // 'network', 'security', 'validation', etc.
  final bool isRecoverable;
  final Map<String, dynamic>? errorContext;
  final int? retryCount;
  final Duration? retryAfter;

  AuthError({
    required this.message,
    this.errorCode,
    this.errorType,
    this.isRecoverable = true,
    this.errorContext,
    this.retryCount,
    this.retryAfter,
    super.timestamp,
    super.stateId,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    message,
    errorCode,
    errorType,
    isRecoverable,
    errorContext,
    retryCount,
    retryAfter,
  ];

  /// Create a copy with updated retry information
  AuthError copyWithRetry({
    int? retryCount,
    Duration? retryAfter,
    String? message,
  }) {
    return AuthError(
      message: message ?? this.message,
      errorCode: errorCode,
      errorType: errorType,
      isRecoverable: isRecoverable,
      errorContext: errorContext,
      retryCount: retryCount ?? this.retryCount,
      retryAfter: retryAfter ?? this.retryAfter,
      timestamp: DateTime.now(),
      stateId: stateId,
    );
  }
}

/// Session expiry warning state
class SessionExpiryWarning extends AuthState {
  final Duration remainingTime;
  final bool canExtend;
  final VoidCallback? onExtend;

  SessionExpiryWarning({
    required this.remainingTime,
    this.canExtend = true,
    this.onExtend,
    super.timestamp,
    super.stateId,
  });

  @override
  List<Object?> get props => [...super.props, remainingTime, canExtend];
}

/// Security alert state for suspicious activities
class SecurityAlert extends AuthState {
  final String alertType;
  final String message;
  final String severity; // 'low', 'medium', 'high', 'critical'
  final Map<String, dynamic>? alertContext;
  final List<String>? recommendedActions;

  SecurityAlert({
    required this.alertType,
    required this.message,
    this.severity = 'medium',
    this.alertContext,
    this.recommendedActions,
    super.timestamp,
    super.stateId,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    alertType,
    message,
    severity,
    alertContext,
    recommendedActions,
  ];
}

/// Biometric authentication state (for future implementation)
class BiometricAuthState extends AuthState {
  final String
  status; // 'available', 'unavailable', 'authenticating', 'success', 'failed'
  final String? biometricType;
  final String? errorMessage;
  final bool fallbackAvailable;

  BiometricAuthState({
    required this.status,
    this.biometricType,
    this.errorMessage,
    this.fallbackAvailable = true,
    super.timestamp,
    super.stateId,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    status,
    biometricType,
    errorMessage,
    fallbackAvailable,
  ];
}

// =====================================================
// STATE EXTENSIONS AND UTILITIES
// =====================================================

/// Extension methods for AuthState
extension AuthStateExtensions on AuthState {
  /// Check if current state is authenticated
  bool get isAuthenticated => this is Authenticated;

  /// Check if current state is loading
  bool get isLoading => this is AuthLoading;

  /// Check if current state has error
  bool get hasError => this is AuthError;

  /// Get authenticated user if available
  User? get user => this is Authenticated ? (this as Authenticated).user : null;

  /// Get error message if available
  String? get errorMessage =>
      this is AuthError ? (this as AuthError).message : null;

  /// Check if state indicates a security issue
  bool get hasSecurityIssue =>
      this is SecurityAlert ||
      (this is AuthError && (this as AuthError).errorType == 'security');

  /// Get state summary for logging/debugging
  String get stateSummary {
    switch (runtimeType) {
      case AuthInitial:
        return 'Initial';
      case AuthLoading:
        final loading = this as AuthLoading;
        return 'Loading(${loading.operation ?? 'unknown'})';
      case Authenticated:
        final auth = this as Authenticated;
        return 'Authenticated(${auth.user?.email ?? 'unknown'})';
      case Unauthenticated:
        final unauth = this as Unauthenticated;
        return 'Unauthenticated(${unauth.reason ?? 'unknown'})';
      case AuthError:
        final error = this as AuthError;
        return 'Error(${error.errorType ?? 'unknown'}: ${error.message})';
      case SecurityAlert:
        final alert = this as SecurityAlert;
        return 'SecurityAlert(${alert.severity}: ${alert.alertType})';
      default:
        return runtimeType.toString();
    }
  }
}

// =====================================================
// TYPE DEFINITIONS
// =====================================================

/// Callback type for handling authentication state changes
typedef AuthStateCallback = void Function(AuthState state);

/// Callback type for handling authentication events
typedef AuthEventCallback = void Function(AuthEvent event);

/// Security context builder type
typedef SecurityContextBuilder = Map<String, dynamic> Function();

/// Permission checker type
typedef PermissionChecker = bool Function(String permission);

// =====================================================
// CONSTANTS
// =====================================================

/// Authentication error codes
class AuthErrorCodes {
  static const String invalidCredentials = 'invalid_credentials';
  static const String networkError = 'network_error';
  static const String serverError = 'server_error';
  static const String userNotFound = 'user_not_found';
  static const String accountDisabled = 'account_disabled';
  static const String tooManyAttempts = 'too_many_attempts';
  static const String sessionExpired = 'session_expired';
  static const String permissionDenied = 'permission_denied';
  static const String biometricUnavailable = 'biometric_unavailable';
  static const String biometricFailed = 'biometric_failed';
}

/// Authentication state types for analytics
class AuthStateTypes {
  static const String initial = 'initial';
  static const String loading = 'loading';
  static const String authenticated = 'authenticated';
  static const String unauthenticated = 'unauthenticated';
  static const String error = 'error';
  static const String securityAlert = 'security_alert';
  static const String sessionWarning = 'session_warning';
  static const String biometric = 'biometric';
}

/// Security alert types
class SecurityAlertTypes {
  static const String suspiciousActivity = 'suspicious_activity';
  static const String multipleFailedAttempts = 'multiple_failed_attempts';
  static const String unrecognizedDevice = 'unrecognized_device';
  static const String locationAnomaly = 'location_anomaly';
  static const String sessionAnomaly = 'session_anomaly';
  static const String permissionEscalation = 'permission_escalation';
}
