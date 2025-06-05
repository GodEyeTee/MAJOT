import 'package:dartz/dartz.dart';
import 'dart:async';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_data_source.dart';
import '../datasources/supabase_user_data_source.dart';
import '../models/user_model.dart';
import '../../../../services/rbac/role_manager.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource firebaseAuthDataSource;
  final SupabaseUserDataSource supabaseUserDataSource;

  UserModel? _cachedUser;
  DateTime? _cacheTimestamp;
  StreamController<Either<Failure, User?>>? _authStateController;

  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  AuthRepositoryImpl({
    required this.firebaseAuthDataSource,
    required this.supabaseUserDataSource,
  }) {
    _initializeAuthStateStream();
  }

  void _initializeAuthStateStream() {
    _authStateController = StreamController<Either<Failure, User?>>.broadcast();

    firebaseAuthDataSource.authStateChanges.listen(
      (firebaseUser) async {
        try {
          await _handleAuthStateChange(firebaseUser);
        } catch (e) {
          LoggerService.error('Auth state change error', 'AUTH_REPO', e);
          _authStateController?.add(Left(UnknownFailure(e.toString())));
        }
      },
      onError: (error) {
        LoggerService.error('Auth stream error', 'AUTH_REPO', error);
        _authStateController?.add(
          Left(AuthFailure('Authentication stream error')),
        );
      },
    );
  }

  Future<void> _handleAuthStateChange(UserModel? firebaseUser) async {
    try {
      if (firebaseUser == null) {
        _clearCache();
        _authStateController?.add(const Right(null));
        return;
      }

      LoggerService.info(
        'Firebase user authenticated: ${firebaseUser.email}',
        'AUTH_REPO',
      );
      final enrichedUser = await _enrichUserWithSupabaseData(firebaseUser);
      _updateCache(enrichedUser);
      _authStateController?.add(Right(enrichedUser));
    } catch (e) {
      LoggerService.error('Error handling auth state change', 'AUTH_REPO', e);
      _authStateController?.add(
        Left(AuthFailure('Failed to process authentication state')),
      );
    }
  }

  Future<UserModel> _enrichUserWithSupabaseData(UserModel firebaseUser) async {
    try {
      LoggerService.info(
        'Enriching Firebase user with Supabase data',
        'AUTH_REPO',
      );

      final supabaseUser = await supabaseUserDataSource.getUser(
        firebaseUser.id,
      );

      if (supabaseUser != null) {
        LoggerService.info('Found existing Supabase user', 'AUTH_REPO');
        return _mergeUserData(firebaseUser, supabaseUser);
      } else {
        LoggerService.info('Creating new Supabase user', 'AUTH_REPO');
        final userToSave = firebaseUser.copyWith(
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await supabaseUserDataSource.saveUser(userToSave);
        return userToSave;
      }
    } catch (e) {
      LoggerService.error('Error enriching user data', 'AUTH_REPO', e);
      return firebaseUser.copyWith(
        lastLoginAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  UserModel _mergeUserData(UserModel firebaseUser, UserModel supabaseUser) {
    return supabaseUser.copyWith(
      email: firebaseUser.email ?? supabaseUser.email,
      emailVerified: firebaseUser.emailVerified,
      photoURL: firebaseUser.photoURL ?? supabaseUser.photoURL,
      provider: firebaseUser.provider,
      linkedProviders: firebaseUser.linkedProviders,
      lastLoginAt: DateTime.now(),
      updatedAt: DateTime.now(),
      role: supabaseUser.role,
      metadata: {
        ...supabaseUser.metadata,
        ...firebaseUser.metadata,
        'last_firebase_sync': DateTime.now().toIso8601String(),
        'role_source': 'supabase_merged',
      },
    );
  }

  @override
  Stream<Either<Failure, User?>> get authStateChanges {
    return _authStateController?.stream ??
        Stream.value(const Left(AuthFailure('Auth stream not initialized')));
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      LoggerService.info('Starting Google sign-in process', 'AUTH_REPO');
      final firebaseUser = await firebaseAuthDataSource.signInWithGoogle();
      final enrichedUser = await _enrichUserWithSupabaseData(firebaseUser);
      _updateCache(enrichedUser);

      // Record login history
      await _recordLoginHistory(enrichedUser.id, true);

      LoggerService.info('Google sign-in completed successfully', 'AUTH_REPO');
      return Right(enrichedUser);
    } on AuthException catch (e) {
      LoggerService.error('Auth exception during sign-in', 'AUTH_REPO', e);
      return Left(AuthFailure(e.message));
    } on DatabaseException catch (e) {
      LoggerService.error('Database exception during sign-in', 'AUTH_REPO', e);
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      LoggerService.error('Unknown error during sign-in', 'AUTH_REPO', e);
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<void> _recordLoginHistory(String userId, bool isSuccessful) async {
    try {
      final deviceInfo = await _getDeviceInfo();

      // Create login history entry
      final loginData = {
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'device': deviceInfo['device'] ?? 'Unknown Device',
        'location': deviceInfo['location'] ?? 'Unknown Location',
        'ip_address': deviceInfo['ip'] ?? '0.0.0.0',
        'is_successful': isSuccessful,
        'created_at': DateTime.now().toIso8601String(),
      };

      await supabaseUserDataSource.saveLoginHistory(loginData);

      LoggerService.info('Login history recorded', 'AUTH_REPO');
    } catch (e) {
      LoggerService.error('Failed to record login history', 'AUTH_REPO', e);
    }
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      // Simple web browser detection
      return {
        'device': 'Web Browser',
        'location': 'Bangkok, Thailand',
        'ip': '127.0.0.1',
      };
    } catch (e) {
      return {'device': 'Unknown', 'location': 'Unknown', 'ip': '0.0.0.0'};
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      LoggerService.info('Starting sign-out process', 'AUTH_REPO');
      await firebaseAuthDataSource.signOut();
      _clearCache();
      LoggerService.info('Sign-out completed', 'AUTH_REPO');
      return const Right(null);
    } on AuthException catch (e) {
      LoggerService.error('Auth exception during sign-out', 'AUTH_REPO', e);
      return Left(AuthFailure(e.message));
    } catch (e) {
      LoggerService.error('Unknown error during sign-out', 'AUTH_REPO', e);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      if (_isCacheValid() && _cachedUser != null) {
        return Right(_cachedUser);
      }

      LoggerService.info('Fetching current user', 'AUTH_REPO');
      final firebaseUser = await firebaseAuthDataSource.getCurrentUser();
      if (firebaseUser == null) {
        _clearCache();
        return const Right(null);
      }

      final enrichedUser = await _enrichUserWithSupabaseData(firebaseUser);
      _updateCache(enrichedUser);
      return Right(enrichedUser);
    } on AuthException catch (e) {
      LoggerService.error(
        'Auth exception getting current user',
        'AUTH_REPO',
        e,
      );
      return Left(AuthFailure(e.message));
    } on DatabaseException catch (e) {
      LoggerService.error(
        'Database exception getting current user',
        'AUTH_REPO',
        e,
      );
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      LoggerService.error('Unknown error getting current user', 'AUTH_REPO', e);
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<Either<Failure, User?>> forceGetCurrentUser() async {
    try {
      LoggerService.info('Force refreshing user data', 'AUTH_REPO');

      _clearCache();
      if (firebaseAuthDataSource is FirebaseAuthDataSourceImpl) {
        (firebaseAuthDataSource as FirebaseAuthDataSourceImpl)
            .forceClearCache();
      }

      final firebaseUser = await firebaseAuthDataSource.getCurrentUser();
      if (firebaseUser == null) {
        return const Right(null);
      }

      final supabaseUser = await supabaseUserDataSource.getUser(
        firebaseUser.id,
      );

      UserModel enrichedUser;
      if (supabaseUser != null) {
        enrichedUser = _mergeUserData(firebaseUser, supabaseUser);
      } else {
        final userToSave = firebaseUser.copyWith(
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await supabaseUserDataSource.saveUser(userToSave);
        enrichedUser = userToSave;
      }

      _updateCache(enrichedUser);
      LoggerService.info('Force refresh completed successfully', 'AUTH_REPO');
      return Right(enrichedUser);
    } on AuthException catch (e) {
      LoggerService.error('Auth error during force refresh', 'AUTH_REPO', e);
      return Left(AuthFailure(e.message));
    } on DatabaseException catch (e) {
      LoggerService.error(
        'Database error during force refresh',
        'AUTH_REPO',
        e,
      );
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      LoggerService.error('Unknown error during force refresh', 'AUTH_REPO', e);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      if (_isCacheValid() && _cachedUser != null) {
        return const Right(true);
      }
      final isAuth = await firebaseAuthDataSource.isAuthenticated();
      return Right(isAuth);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  bool _isCacheValid() {
    if (_cachedUser == null || _cacheTimestamp == null) {
      return false;
    }
    return DateTime.now().difference(_cacheTimestamp!) < _cacheValidityDuration;
  }

  void _updateCache(UserModel user) {
    _cachedUser = user;
    _cacheTimestamp = DateTime.now();
  }

  void _clearCache() {
    _cachedUser = null;
    _cacheTimestamp = null;
  }

  void dispose() {
    _authStateController?.close();
    _clearCache();
    LoggerService.info('AuthRepositoryImpl disposed', 'AUTH_REPO');
  }
}
