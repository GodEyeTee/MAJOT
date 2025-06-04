import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/logger_service.dart';
import '../models/user_model.dart';

abstract class FirebaseAuthDataSource {
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
  Future<bool> isAuthenticated();
  Future<void> refreshToken();
  Future<String?> getIdToken({bool forceRefresh = false});
}

class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  static const Duration _tokenRefreshThreshold = Duration(minutes: 55);
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const int _maxFailedAttempts = 5; // Add max failed attempts constant

  final firebase.FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;

  // Security monitoring
  int _failedAttempts = 0;
  DateTime? _lastFailedAttempt; // Add timestamp tracking
  DateTime? _lastTokenRefresh;
  UserModel? _cachedUser;
  DateTime? _cacheTimestamp;

  // Streaming
  StreamController<UserModel?>? _authStateController;
  StreamSubscription<firebase.User?>? _firebaseAuthSubscription;

  FirebaseAuthDataSourceImpl({
    required this.firebaseAuth,
    required this.googleSignIn,
  }) {
    _initializeAuthStateListener();
    LoggerService.info('Firebase Auth Data Source initialized', 'AUTH');
  }

  void _initializeAuthStateListener() {
    _authStateController = StreamController<UserModel?>.broadcast();

    _firebaseAuthSubscription = firebaseAuth.authStateChanges().listen(
      (firebase.User? firebaseUser) {
        try {
          final userModel =
              firebaseUser != null
                  ? UserModel.fromFirebaseUser(firebaseUser)
                  : null;

          _updateCache(userModel);
          _authStateController?.add(userModel);
        } catch (e) {
          LoggerService.error('Error processing auth state change', 'AUTH', e);
          _authStateController?.addError(
            AuthException(
              'Failed to process authentication state: ${e.toString()}',
            ),
          );
        }
      },
      onError: (error) {
        LoggerService.error('Firebase auth stream error', 'AUTH', error);
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

  void _checkFailedAttempts() {
    // Reset counter if last failed attempt was more than 30 minutes ago
    if (_lastFailedAttempt != null &&
        DateTime.now().difference(_lastFailedAttempt!) >
            const Duration(minutes: 30)) {
      _failedAttempts = 0;
      _lastFailedAttempt = null;
    }

    // Check if too many failed attempts
    if (_failedAttempts >= _maxFailedAttempts) {
      throw const AuthException(
        'Too many failed attempts. Please try again later.',
        code: 'TOO_MANY_FAILED_ATTEMPTS',
      );
    }
  }

  void _recordFailedAttempt() {
    _failedAttempts++;
    _lastFailedAttempt = DateTime.now();
    LoggerService.warning(
      'Failed attempt recorded: $_failedAttempts/$_maxFailedAttempts',
      'AUTH',
    );
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    return await _executeWithRetry(() async {
      try {
        _checkFailedAttempts(); // Check before attempting sign in

        LoggerService.info('Starting Google Sign-In process', 'AUTH');

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw const AuthException(
            'Google sign-in was canceled by the user',
            code: 'SIGN_IN_CANCELED',
          );
        }

        if (googleUser.email.isEmpty) {
          throw const AuthException(
            'Invalid Google account - no email provided',
            code: 'INVALID_ACCOUNT',
          );
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        if (googleAuth.accessToken == null || googleAuth.idToken == null) {
          throw const AuthException(
            'Failed to get Google authentication tokens',
            code: 'TOKEN_ERROR',
          );
        }

        final credential = firebase.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await firebaseAuth.signInWithCredential(
          credential,
        );
        if (userCredential.user == null) {
          throw const AuthException(
            'Failed to authenticate with Firebase',
            code: 'FIREBASE_AUTH_FAILED',
          );
        }

        final userModel = UserModel.fromFirebaseUser(userCredential.user!);
        _updateCache(userModel);
        _failedAttempts = 0; // Reset on success
        _lastFailedAttempt = null;

        LoggerService.info(
          'Google Sign-In successful: ${userModel.email}',
          'AUTH',
        );
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
        LoggerService.info('Starting sign-out process', 'AUTH');

        try {
          await googleSignIn.signOut();
        } catch (e) {
          LoggerService.warning('Google sign-out warning: $e', 'AUTH');
        }

        await firebaseAuth.signOut();
        _clearCache();
        _failedAttempts = 0;
        _lastFailedAttempt = null;

        LoggerService.info('Sign-out successful', 'AUTH');
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
      if (_isCacheValid()) {
        return _cachedUser;
      }

      final firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser == null) {
        _clearCache();
        return null;
      }

      await _refreshTokenIfNeeded(firebaseUser);
      final userModel = UserModel.fromFirebaseUser(firebaseUser);
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
      if (_isCacheValid() && _cachedUser != null) {
        return true;
      }

      final user = firebaseAuth.currentUser;
      final isAuth = user != null;

      if (!isAuth) {
        _clearCache();
      } else {
        final userModel = UserModel.fromFirebaseUser(user);
        _updateCache(userModel);
      }

      return isAuth;
    } catch (e) {
      LoggerService.warning('Authentication check error: $e', 'AUTH');
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

      await user.getIdToken(true);
      _lastTokenRefresh = DateTime.now();

      LoggerService.info('Firebase token refreshed successfully', 'AUTH');
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

  bool _shouldRefreshToken() {
    if (_lastTokenRefresh == null) return true;
    return DateTime.now().difference(_lastTokenRefresh!) >
        _tokenRefreshThreshold;
  }

  Future<void> _refreshTokenIfNeeded(firebase.User user) async {
    if (_shouldRefreshToken()) {
      try {
        await user.getIdToken(true);
        _lastTokenRefresh = DateTime.now();
      } catch (e) {
        LoggerService.warning('Token refresh warning: $e', 'AUTH');
      }
    }
  }

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

        if (e is firebase.FirebaseAuthException) {
          switch (e.code) {
            case 'network-request-failed':
            case 'internal-error':
              LoggerService.info(
                'Retrying Firebase operation (attempt $attempts/$_maxRetryAttempts)',
                'AUTH',
              );
              await Future.delayed(_retryDelay * attempts);
              continue;
          }
        }

        rethrow;
      }
    }

    throw Exception('Max retry attempts exceeded');
  }

  void forceClearCache() {
    _clearCache();
    _failedAttempts = 0;
    _lastFailedAttempt = null;
    _lastTokenRefresh = null;
    LoggerService.info('Firebase Auth cache forcefully cleared', 'AUTH');
  }

  void dispose() {
    _firebaseAuthSubscription?.cancel();
    _authStateController?.close();
    _clearCache();
    LoggerService.info('Firebase Auth Data Source disposed', 'AUTH');
  }
}
