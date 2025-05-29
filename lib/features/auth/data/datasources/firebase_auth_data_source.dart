import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import 'dart:async';

/// Abstract Firebase authentication data source interface
abstract class FirebaseAuthDataSource {
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
  Future<bool> isAuthenticated();
  Future<void> refreshToken();
  Future<String?> getIdToken({bool forceRefresh = false});
}

/// Enhanced Firebase authentication data source implementation
/// Provides comprehensive authentication services with security monitoring
class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  final firebase.FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;

  // Security and performance monitoring
  int _signInAttempts = 0;
  int _failedAttempts = 0;
  DateTime? _lastSignInAttempt;
  DateTime? _lastTokenRefresh;
  UserModel? _cachedUser;
  DateTime? _cacheTimestamp;

  // Streaming
  StreamController<UserModel?>? _authStateController;
  StreamSubscription<firebase.User?>? _firebaseAuthSubscription;

  // Configuration
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  static const Duration _tokenRefreshThreshold = Duration(
    minutes: 55,
  ); // Refresh before 1 hour expiry
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  FirebaseAuthDataSourceImpl({
    required this.firebaseAuth,
    required this.googleSignIn,
  }) {
    _initializeAuthStateListener();
    if (!kReleaseMode) {
      print('🔥 Firebase Auth Data Source initialized');
    }
  }

  /// Initialize Firebase auth state listener with comprehensive error handling
  void _initializeAuthStateListener() {
    _authStateController = StreamController<UserModel?>.broadcast();

    _firebaseAuthSubscription = firebaseAuth.authStateChanges().listen(
      (firebase.User? firebaseUser) {
        try {
          final userModel =
              firebaseUser != null
                  ? UserModel.fromFirebaseUser(firebaseUser)
                  : null;

          // Update cache
          _updateCache(userModel);

          // Emit to stream
          _authStateController?.add(userModel);

          if (!kReleaseMode) {
            print(
              '🔄 Firebase auth state changed: ${userModel?.email ?? 'signed out'}',
            );
          }
        } catch (e) {
          if (!kReleaseMode) {
            print('❌ Error processing auth state change: $e');
          }
          _authStateController?.addError(
            AuthException(
              'Failed to process authentication state: ${e.toString()}',
            ),
          );
        }
      },
      onError: (error) {
        if (!kReleaseMode) {
          print('❌ Firebase auth stream error: $error');
        }
        _authStateController?.addError(
          AuthException('Authentication stream error: ${error.toString()}'),
        );
      },
    );
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _authStateController?.stream ?? Stream.value(null);
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    return await _executeWithRetry(() async {
      _recordSignInAttempt();

      try {
        if (!kReleaseMode) {
          print('🔄 Starting Google Sign-In process...');
        }

        // Start Google Sign-In flow
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          throw const AuthException(
            'Google sign-in was canceled by the user',
            code: 'SIGN_IN_CANCELED',
          );
        }

        // Verify Google account
        if (googleUser.email.isEmpty) {
          throw const AuthException(
            'Invalid Google account - no email provided',
            code: 'INVALID_ACCOUNT',
          );
        }

        // Get authentication details
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        if (googleAuth.accessToken == null || googleAuth.idToken == null) {
          throw const AuthException(
            'Failed to get Google authentication tokens',
            code: 'TOKEN_ERROR',
          );
        }

        // Create Firebase credential
        final credential = firebase.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase
        final userCredential = await firebaseAuth.signInWithCredential(
          credential,
        );

        if (userCredential.user == null) {
          throw const AuthException(
            'Failed to authenticate with Firebase',
            code: 'FIREBASE_AUTH_FAILED',
          );
        }

        // Create enhanced user model
        final userModel = UserModel.fromFirebaseUser(userCredential.user!);

        // Update cache
        _updateCache(userModel);

        // Reset failure counters on success
        _resetFailureCounters();

        _logSuccessfulSignIn(userModel);

        return userModel;
      } on firebase.FirebaseAuthException catch (e) {
        _recordFailedAttempt();
        throw _handleFirebaseAuthException(e);
      } on AuthException {
        _recordFailedAttempt();
        rethrow;
      } catch (e) {
        _recordFailedAttempt();
        throw AuthException(
          'Sign-in failed: ${e.toString()}',
          code: 'SIGN_IN_ERROR',
          cause: e,
        );
      }
    });
  }

  @override
  Future<void> signOut() async {
    return await _executeWithRetry(() async {
      try {
        if (!kReleaseMode) {
          print('🔄 Starting sign-out process...');
        }

        final currentUser = _cachedUser;

        // Sign out from Google
        try {
          await googleSignIn.signOut();
        } catch (e) {
          if (!kReleaseMode) {
            print('⚠️ Google sign-out warning: $e');
          }
          // Continue with Firebase sign-out even if Google sign-out fails
        }

        // Sign out from Firebase
        await firebaseAuth.signOut();

        // Clear cache
        _clearCache();

        // Reset counters
        _resetFailureCounters();

        _logSuccessfulSignOut(currentUser);
      } on firebase.FirebaseAuthException catch (e) {
        throw _handleFirebaseAuthException(e);
      } catch (e) {
        throw AuthException(
          'Sign-out failed: ${e.toString()}',
          code: 'SIGN_OUT_ERROR',
          cause: e,
        );
      }
    });
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      // Return cached user if valid
      if (_isCacheValid()) {
        return _cachedUser;
      }

      // Get current Firebase user
      final firebaseUser = firebaseAuth.currentUser;

      if (firebaseUser == null) {
        _clearCache();
        return null;
      }

      // Refresh token if needed
      await _refreshTokenIfNeeded(firebaseUser);

      // Create user model
      final userModel = UserModel.fromFirebaseUser(firebaseUser);

      // Update cache
      _updateCache(userModel);

      return userModel;
    } on firebase.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException(
        'Failed to get current user: ${e.toString()}',
        code: 'GET_USER_ERROR',
        cause: e,
      );
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      // Check cache first
      if (_isCacheValid() && _cachedUser != null) {
        return true;
      }

      // Check Firebase auth state
      final user = firebaseAuth.currentUser;
      final isAuth = user != null;

      // Update cache based on result
      if (!isAuth) {
        _clearCache();
      } else {
        final userModel = UserModel.fromFirebaseUser(user);
        _updateCache(userModel);
      }

      return isAuth;
    } catch (e) {
      if (!kReleaseMode) {
        print('⚠️ Authentication check error: $e');
      }
      return false;
    }
  }

  @override
  Future<void> refreshToken() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No authenticated user to refresh token');
      }

      // Force token refresh
      await user.getIdToken(true);
      _lastTokenRefresh = DateTime.now();

      if (!kReleaseMode) {
        print('✅ Firebase token refreshed successfully');
      }
    } on firebase.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException(
        'Token refresh failed: ${e.toString()}',
        code: 'TOKEN_REFRESH_ERROR',
        cause: e,
      );
    }
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return null;

      // Check if token refresh is needed
      final shouldRefresh = forceRefresh || _shouldRefreshToken();

      final token = await user.getIdToken(shouldRefresh);

      if (shouldRefresh) {
        _lastTokenRefresh = DateTime.now();
      }

      return token;
    } on firebase.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException(
        'Failed to get ID token: ${e.toString()}',
        code: 'GET_TOKEN_ERROR',
        cause: e,
      );
    }
  }

  /// Check if token should be refreshed
  bool _shouldRefreshToken() {
    if (_lastTokenRefresh == null) return true;
    return DateTime.now().difference(_lastTokenRefresh!) >
        _tokenRefreshThreshold;
  }

  /// Refresh token if needed
  Future<void> _refreshTokenIfNeeded(firebase.User user) async {
    if (_shouldRefreshToken()) {
      try {
        await user.getIdToken(true);
        _lastTokenRefresh = DateTime.now();
      } catch (e) {
        if (!kReleaseMode) {
          print('⚠️ Token refresh warning: $e');
        }
        // Don't throw - continue with potentially stale token
      }
    }
  }

  /// Handle Firebase Auth exceptions with enhanced error mapping
  AuthException _handleFirebaseAuthException(firebase.FirebaseAuthException e) {
    String userMessage;
    String code;

    switch (e.code) {
      case 'user-not-found':
        userMessage =
            'Account not found. Please check your credentials or sign up.';
        code = 'USER_NOT_FOUND';
        break;
      case 'wrong-password':
        userMessage = 'Invalid password. Please try again.';
        code = 'WRONG_PASSWORD';
        break;
      case 'user-disabled':
        userMessage = 'Your account has been disabled. Please contact support.';
        code = 'ACCOUNT_DISABLED';
        break;
      case 'too-many-requests':
        userMessage = 'Too many failed attempts. Please try again later.';
        code = 'TOO_MANY_ATTEMPTS';
        break;
      case 'operation-not-allowed':
        userMessage =
            'This sign-in method is not enabled. Please contact support.';
        code = 'OPERATION_NOT_ALLOWED';
        break;
      case 'account-exists-with-different-credential':
        userMessage =
            'An account already exists with this email using a different sign-in method.';
        code = 'ACCOUNT_EXISTS_DIFFERENT_CREDENTIAL';
        break;
      case 'invalid-credential':
        userMessage =
            'The credential is invalid or has expired. Please try again.';
        code = 'INVALID_CREDENTIAL';
        break;
      case 'network-request-failed':
        userMessage =
            'Network error. Please check your connection and try again.';
        code = 'NETWORK_ERROR';
        break;
      case 'internal-error':
        userMessage = 'An internal error occurred. Please try again later.';
        code = 'INTERNAL_ERROR';
        break;
      default:
        userMessage = 'Authentication failed: ${e.message ?? 'Unknown error'}';
        code = e.code.toUpperCase().replaceAll('-', '_');
    }

    return AuthException(
      userMessage,
      code: code,
      cause: e,
      context: {'firebase_code': e.code, 'firebase_message': e.message},
    );
  }

  // Cache Management

  bool _isCacheValid() {
    if (_cachedUser == null || _cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheValidityDuration;
  }

  void _updateCache(UserModel? user) {
    _cachedUser = user;
    _cacheTimestamp = DateTime.now();
  }

  void _clearCache() {
    _cachedUser = null;
    _cacheTimestamp = null;
  }

  // Security Monitoring

  void _recordSignInAttempt() {
    _signInAttempts++;
    _lastSignInAttempt = DateTime.now();
  }

  void _recordFailedAttempt() {
    _failedAttempts++;
  }

  void _resetFailureCounters() {
    _failedAttempts = 0;
  }

  void _logSuccessfulSignIn(UserModel user) {
    if (!kReleaseMode) {
      print('✅ Google Sign-In successful:');
      print('   Email: ${user.email}');
      print('   Display Name: ${user.displayName}');
      print('   Provider: ${user.provider}');
      print('   Email Verified: ${user.emailVerified}');
    }
  }

  void _logSuccessfulSignOut(UserModel? user) {
    if (!kReleaseMode) {
      print('✅ Sign-Out successful');
      if (user != null) {
        print('   Previous user: ${user.email}');
      }
    }
  }

  // Error Handling and Retry Logic

  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    int attempts = 0;

    while (attempts < _maxRetryAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempts++;

        if (attempts >= _maxRetryAttempts) {
          rethrow;
        }

        // Only retry on specific exceptions
        if (e is firebase.FirebaseAuthException) {
          switch (e.code) {
            case 'network-request-failed':
            case 'internal-error':
              if (!kReleaseMode) {
                print(
                  '🔄 Retrying Firebase operation (attempt $attempts/$_maxRetryAttempts)',
                );
              }
              await Future.delayed(_retryDelay * attempts);
              continue;
          }
        }

        // Don't retry other exceptions
        rethrow;
      }
    }

    throw Exception('Max retry attempts exceeded');
  }

  // Health and Diagnostics

  /// Get authentication health status
  Map<String, dynamic> getHealthStatus() {
    final now = DateTime.now();

    return {
      'firebase_user_available': firebaseAuth.currentUser != null,
      'google_signin_available': true, // GoogleSignIn is always available
      'cache_valid': _isCacheValid(),
      'cached_user_email': _cachedUser?.email,
      'cache_age_seconds':
          _cacheTimestamp != null
              ? now.difference(_cacheTimestamp!).inSeconds
              : null,
      'sign_in_attempts': _signInAttempts,
      'failed_attempts': _failedAttempts,
      'success_rate':
          _signInAttempts > 0
              ? '${(((_signInAttempts - _failedAttempts) / _signInAttempts) * 100).toStringAsFixed(1)}%'
              : '0%',
      'last_sign_in_attempt': _lastSignInAttempt?.toIso8601String(),
      'last_token_refresh': _lastTokenRefresh?.toIso8601String(),
      'token_refresh_needed': _shouldRefreshToken(),
      'stream_active':
          _authStateController != null && !_authStateController!.isClosed,
    };
  }

  /// Get security metrics
  Map<String, dynamic> getSecurityMetrics() {
    if (kReleaseMode) return {'status': 'production_mode'};

    return {
      'authentication_attempts': _signInAttempts,
      'failed_attempts': _failedAttempts,
      'success_rate':
          _signInAttempts > 0
              ? '${((_signInAttempts - _failedAttempts) / _signInAttempts * 100).toStringAsFixed(1)}%'
              : '0%',
      'current_user_verified': _cachedUser?.emailVerified ?? false,
      'token_management': {
        'last_refresh': _lastTokenRefresh?.toIso8601String(),
        'refresh_needed': _shouldRefreshToken(),
        'refresh_threshold_minutes': _tokenRefreshThreshold.inMinutes,
      },
      'cache_performance': {
        'cache_valid': _isCacheValid(),
        'cache_age_seconds':
            _cacheTimestamp != null
                ? DateTime.now().difference(_cacheTimestamp!).inSeconds
                : null,
        'cache_validity_minutes': _cacheValidityDuration.inMinutes,
      },
    };
  }

  /// Force clear all cached data
  void forceClearCache() {
    _clearCache();
    _resetFailureCounters();
    _lastTokenRefresh = null;

    if (!kReleaseMode) {
      print('🧹 Firebase Auth cache forcefully cleared');
    }
  }

  /// Validate current authentication state
  Future<bool> validateAuthState() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return false;

      // Try to get a fresh token to validate the session
      await user.getIdToken(true);
      return true;
    } catch (e) {
      if (!kReleaseMode) {
        print('⚠️ Auth state validation failed: $e');
      }
      return false;
    }
  }

  /// Get user metadata
  Map<String, dynamic>? getUserMetadata() {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;

    return {
      'uid': user.uid,
      'email': user.email,
      'display_name': user.displayName,
      'photo_url': user.photoURL,
      'email_verified': user.emailVerified,
      'is_anonymous': user.isAnonymous,
      'creation_time': user.metadata.creationTime?.toIso8601String(),
      'last_sign_in_time': user.metadata.lastSignInTime?.toIso8601String(),
      'provider_data':
          user.providerData
              .map(
                (info) => {
                  'provider_id': info.providerId,
                  'uid': info.uid,
                  'email': info.email,
                  'display_name': info.displayName,
                  'photo_url': info.photoURL,
                },
              )
              .toList(),
    };
  }

  // Cleanup

  void dispose() {
    _firebaseAuthSubscription?.cancel();
    _authStateController?.close();
    _clearCache();

    if (!kReleaseMode) {
      print('🧹 Firebase Auth Data Source disposed');
    }
  }
}

/// Enhanced Google Sign-In configuration
class GoogleSignInConfig {
  static GoogleSignIn createInstance({
    List<String>? scopes,
    String? hostedDomain,
    bool forceCodeForRefreshToken = false,
  }) {
    return GoogleSignIn(
      scopes: scopes ?? ['email', 'profile'],
      hostedDomain: hostedDomain,
      forceCodeForRefreshToken: forceCodeForRefreshToken,
    );
  }

  /// Get recommended configuration for production
  static GoogleSignIn getProductionConfig({String? hostedDomain}) {
    return createInstance(
      scopes: ['email', 'profile'],
      hostedDomain: hostedDomain,
      forceCodeForRefreshToken: true, // Better security for production
    );
  }

  /// Get development configuration
  static GoogleSignIn getDevelopmentConfig() {
    return createInstance(
      scopes: [
        'email',
        'profile',
        'openid', // Additional scope for development
      ],
      forceCodeForRefreshToken: false, // Faster development experience
    );
  }
}

/// Firebase Auth configuration helper
class FirebaseAuthConfig {
  /// Configure Firebase Auth settings
  static Future<void> configure() async {
    try {
      final auth = firebase.FirebaseAuth.instance;

      // Set language code
      await auth.setLanguageCode('en');

      // Configure auth settings
      await auth.authStateChanges().first.timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );

      if (!kReleaseMode) {
        print('✅ Firebase Auth configured');
      }
    } catch (e) {
      if (!kReleaseMode) {
        print('⚠️ Firebase Auth configuration warning: $e');
      }
    }
  }

  /// Get current app verification status
  static Map<String, dynamic> getAppVerificationStatus() {
    return {
      'app_check_enabled': false, // Would be true if App Check is configured
      'reCAPTCHA_enabled': false, // Would be true if reCAPTCHA is configured
      'safety_net_enabled': false, // Would be true if SafetyNet is configured
    };
  }
}
