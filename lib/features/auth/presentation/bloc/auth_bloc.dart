import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../services/rbac/rbac_service.dart';
import '../../domain/usecases/is_authenticated.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'dart:async';

/// Security-First Authentication BLoC
/// Implements comprehensive authentication management with RBAC integration
/// Performance optimized with state caching and efficient stream handling
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Dependencies
  final SignInWithGoogle signInWithGoogleUseCase;
  final SignOut signOutUseCase;
  final IsAuthenticated isAuthenticatedUseCase;
  final GetCurrentUser getCurrentUserUseCase;
  final AuthRepository authRepository;
  final RBACService _rbacService;

  // State Management
  late final StreamSubscription _authStateSubscription;
  bool _isInitialized = false;
  User? _cachedUser;
  DateTime? _lastAuthCheck;
  Timer? _sessionValidationTimer;

  // Performance & Security Metrics
  int _signInAttempts = 0;
  DateTime? _lastSignInAttempt;
  static const int _maxSignInAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  static const Duration _sessionValidationInterval = Duration(minutes: 5);

  AuthBloc({
    required this.signInWithGoogleUseCase,
    required this.signOutUseCase,
    required this.isAuthenticatedUseCase,
    required this.getCurrentUserUseCase,
    required this.authRepository,
    RBACService? rbacService,
  }) : _rbacService = rbacService ?? RBACService(),
       super(AuthInitial()) {
    // Register event handlers
    _registerEventHandlers();

    // Initialize authentication state monitoring
    _initializeAuthStateMonitoring();

    // Start session validation
    _startSessionValidation();

    if (!kReleaseMode) {
      print('🔐 AuthBloc initialized with security monitoring');
    }
  }

  /// Register all event handlers with comprehensive error handling
  void _registerEventHandlers() {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignOutEvent>(_onSignOut);
    on<AuthStateChangedEvent>(_onAuthStateChanged);
    on<ValidateSessionEvent>(_onValidateSession);
    on<RefreshUserDataEvent>(_onRefreshUserData);
  }

  /// Initialize authentication state monitoring with security logging
  void _initializeAuthStateMonitoring() {
    _authStateSubscription = authRepository.authStateChanges.listen(
      (userResult) {
        userResult.fold(
          (failure) {
            if (!kReleaseMode) {
              print('❌ Auth state error: ${failure.message}');
            }
            add(AuthStateChangedEvent(failure: failure));
          },
          (user) {
            if (!kReleaseMode) {
              print('🔄 Auth state changed: ${user?.email ?? 'signed out'}');
            }
            add(AuthStateChangedEvent(user: user));
          },
        );
      },
      onError: (error) {
        if (!kReleaseMode) {
          print('❌ Auth stream error: $error');
        }
        add(
          AuthStateChangedEvent(
            failure: _createGenericFailure('Authentication stream error'),
          ),
        );
      },
    );
  }

  /// Start periodic session validation for enhanced security
  void _startSessionValidation() {
    _sessionValidationTimer = Timer.periodic(
      _sessionValidationInterval,
      (_) => add(ValidateSessionEvent()),
    );
  }

  /// Handle authentication state changes with security context updates
  Future<void> _onAuthStateChanged(
    AuthStateChangedEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Update initialization status
      _isInitialized = true;
      _lastAuthCheck = DateTime.now();

      // Handle authentication failure
      if (event.failure != null) {
        _clearSecurityContext();
        emit(AuthError(message: event.failure!.message));
        return;
      }

      // Handle user authentication state
      if (event.user != null) {
        await _handleUserAuthenticated(event.user!, emit);
      } else {
        await _handleUserSignedOut(emit);
      }
    } catch (e) {
      if (!kReleaseMode) {
        print('❌ Auth state change handling error: $e');
      }
      emit(AuthError(message: 'Authentication state update failed'));
    }
  }

  /// Handle user authenticated state with security setup
  Future<void> _handleUserAuthenticated(
    User user,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Cache user data for performance
      _cachedUser = user;

      // Set up RBAC security context
      _rbacService.setCurrentUser(user);

      // Reset security counters on successful auth
      _resetSecurityCounters();

      // Emit authenticated state
      emit(Authenticated(user: user));

      // Security logging
      if (!kReleaseMode) {
        print('✅ User authenticated: ${user.email}');
        print('🎭 User role: ${user.role}');
        _rbacService.printCurrentUserInfo();
      }
    } catch (e) {
      if (!kReleaseMode) {
        print('❌ User authentication handling error: $e');
      }
      emit(AuthError(message: 'Authentication setup failed'));
    }
  }

  /// Handle user signed out state with security cleanup
  Future<void> _handleUserSignedOut(Emitter<AuthState> emit) async {
    try {
      // Clear security context
      _clearSecurityContext();

      // Emit unauthenticated state
      emit(Unauthenticated());

      if (!kReleaseMode) {
        print('👋 User signed out successfully');
      }
    } catch (e) {
      if (!kReleaseMode) {
        print('❌ Sign out handling error: $e');
      }
      emit(AuthError(message: 'Sign out processing failed'));
    }
  }

  /// Check authentication status with caching for performance
  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Show loading for initial check
      if (!_isInitialized) {
        emit(AuthLoading());
      }

      // Use cached data if recent and available
      if (_canUseCachedAuth()) {
        if (_cachedUser != null) {
          _rbacService.setCurrentUser(_cachedUser);
          emit(Authenticated(user: _cachedUser));
        } else {
          emit(Unauthenticated());
        }
        return;
      }

      // Perform fresh authentication check
      final result = await getCurrentUserUseCase(const NoParams());

      result.fold(
        (failure) {
          if (!kReleaseMode) {
            print('❌ Auth check failed: ${failure.message}');
          }
          emit(AuthError(message: failure.message));
        },
        (user) {
          _lastAuthCheck = DateTime.now();
          if (user != null) {
            _cachedUser = user;
            _rbacService.setCurrentUser(user);
            emit(Authenticated(user: user));
          } else {
            _cachedUser = null;
            _rbacService.setCurrentUser(null);
            emit(Unauthenticated());
          }
        },
      );
    } catch (e) {
      if (!kReleaseMode) {
        print('❌ Auth check error: $e');
      }
      emit(AuthError(message: 'Authentication check failed'));
    }
  }

  /// Handle Google Sign-In with security rate limiting
  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Security: Check rate limiting
      if (_isSignInRateLimited()) {
        final timeRemaining = _getRemainingLockoutTime();
        emit(
          AuthError(
            message:
                'Too many sign-in attempts. Try again in ${timeRemaining.inMinutes} minutes.',
          ),
        );
        return;
      }

      // Show loading state
      emit(AuthLoading());

      // Record sign-in attempt
      _recordSignInAttempt();

      // Perform sign-in
      final result = await signInWithGoogleUseCase(const NoParams());

      result.fold(
        (failure) {
          if (!kReleaseMode) {
            print('❌ Google sign-in failed: ${failure.message}');
          }
          emit(AuthError(message: failure.message));
        },
        (user) {
          // Success will be handled by authStateChanges stream
          if (!kReleaseMode) {
            print('✅ Google sign-in initiated for: ${user.email}');
          }
        },
      );
    } catch (e) {
      if (!kReleaseMode) {
        print('❌ Google sign-in error: $e');
      }
      emit(AuthError(message: 'Sign-in process failed'));
    }
  }

  /// Handle sign out with security cleanup
  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());

      final result = await signOutUseCase(const NoParams());

      result.fold(
        (failure) {
          if (!kReleaseMode) {
            print('❌ Sign out failed: ${failure.message}');
          }
          emit(AuthError(message: failure.message));
        },
        (_) {
          // Success will be handled by authStateChanges stream
          if (!kReleaseMode) {
            print('✅ Sign out initiated');
          }
        },
      );
    } catch (e) {
      if (!kReleaseMode) {
        print('❌ Sign out error: $e');
      }
      emit(AuthError(message: 'Sign out failed'));
    }
  }

  /// Validate current session for security
  Future<void> _onValidateSession(
    ValidateSessionEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Skip validation if not authenticated
      if (!isAuthenticated) return;

      // Perform silent session validation
      final result = await isAuthenticatedUseCase(const NoParams());

      result.fold(
        (failure) {
          if (!kReleaseMode) {
            print('⚠️ Session validation failed: ${failure.message}');
          }
          // Force sign out on session failure
          add(SignOutEvent());
        },
        (isValid) {
          if (!isValid) {
            if (!kReleaseMode) {
              print('⚠️ Session invalid, signing out');
            }
            add(SignOutEvent());
          } else if (!kReleaseMode) {
            print('✅ Session validation passed');
          }
        },
      );
    } catch (e) {
      if (!kReleaseMode) {
        print('❌ Session validation error: $e');
      }
    }
  }

  /// Refresh user data for updated permissions
  Future<void> _onRefreshUserData(
    RefreshUserDataEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (!isAuthenticated) return;

      final result = await getCurrentUserUseCase(const NoParams());

      result.fold(
        (failure) {
          if (!kReleaseMode) {
            print('❌ User data refresh failed: ${failure.message}');
          }
        },
        (user) {
          if (user != null) {
            _cachedUser = user;
            _rbacService.setCurrentUser(user);
            emit(Authenticated(user: user));

            if (!kReleaseMode) {
              print('✅ User data refreshed');
            }
          }
        },
      );
    } catch (e) {
      if (!kReleaseMode) {
        print('❌ User data refresh error: $e');
      }
    }
  }

  // Security Helper Methods

  bool _isSignInRateLimited() {
    if (_signInAttempts < _maxSignInAttempts) return false;

    final lastAttempt = _lastSignInAttempt;
    if (lastAttempt == null) return false;

    return DateTime.now().difference(lastAttempt) < _lockoutDuration;
  }

  Duration _getRemainingLockoutTime() {
    final lastAttempt = _lastSignInAttempt;
    if (lastAttempt == null) return Duration.zero;

    final elapsed = DateTime.now().difference(lastAttempt);
    return _lockoutDuration - elapsed;
  }

  void _recordSignInAttempt() {
    _signInAttempts++;
    _lastSignInAttempt = DateTime.now();
  }

  void _resetSecurityCounters() {
    _signInAttempts = 0;
    _lastSignInAttempt = null;
  }

  void _clearSecurityContext() {
    _cachedUser = null;
    _rbacService.setCurrentUser(null);
  }

  bool _canUseCachedAuth() {
    final lastCheck = _lastAuthCheck;
    if (lastCheck == null) return false;

    return DateTime.now().difference(lastCheck) < const Duration(minutes: 1);
  }

  dynamic _createGenericFailure(String message) {
    // Return appropriate failure type based on your failure classes
    return Exception(message);
  }

  // Public Getters

  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => state is Authenticated;
  User? get currentUser => _cachedUser;

  /// Get authentication status with role information
  Map<String, dynamic> get authStatus {
    if (!kReleaseMode) {
      return {
        'initialized': _isInitialized,
        'authenticated': isAuthenticated,
        'user_email': _cachedUser?.email,
        'user_role': _cachedUser?.role.toString(),
        'last_check': _lastAuthCheck?.toIso8601String(),
        'sign_in_attempts': _signInAttempts,
        'rate_limited': _isSignInRateLimited(),
      };
    }
    return {'initialized': _isInitialized, 'authenticated': isAuthenticated};
  }

  /// Get security metrics for monitoring
  Map<String, dynamic> get securityMetrics {
    if (kReleaseMode) {
      return {'status': 'production_mode'};
    }

    return {
      'sign_in_attempts': _signInAttempts,
      'rate_limited': _isSignInRateLimited(),
      'session_valid': isAuthenticated,
      'last_auth_check': _lastAuthCheck?.toIso8601String(),
      'rbac_status': _rbacService.currentUser != null ? 'active' : 'inactive',
      'cache_valid': _canUseCachedAuth(),
    };
  }

  @override
  Future<void> close() async {
    try {
      // Cancel timers
      _sessionValidationTimer?.cancel();

      // Cancel subscriptions
      await _authStateSubscription.cancel();

      // Clear security context
      _clearSecurityContext();

      if (!kReleaseMode) {
        print('🧹 AuthBloc disposed with security cleanup');
      }
    } catch (e) {
      if (!kReleaseMode) {
        print('⚠️ AuthBloc disposal error: $e');
      }
    }

    return super.close();
  }
}
