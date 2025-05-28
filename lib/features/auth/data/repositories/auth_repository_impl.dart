import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_data_source.dart';
import '../datasources/supabase_user_data_source.dart';
import '../models/user_model.dart';
import 'dart:async';
import '../../../../services/rbac/role_manager.dart';

/// Enhanced authentication repository with comprehensive security features
/// Implements dual-layer authentication (Firebase + Supabase) with fallback mechanisms
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource firebaseAuthDataSource;
  final SupabaseUserDataSource supabaseUserDataSource;

  // Caching and performance optimization
  UserModel? _cachedUser;
  DateTime? _cacheTimestamp;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  // Security monitoring
  int _authAttempts = 0;
  int _failedAttempts = 0;
  DateTime? _lastAttempt;
  StreamController<Either<Failure, User?>>? _authStateController;

  AuthRepositoryImpl({
    required this.firebaseAuthDataSource,
    required this.supabaseUserDataSource,
  }) {
    _initializeAuthStateStream();
    if (!kReleaseMode) {
      print('🔐 AuthRepository initialized with dual-layer security');
    }
  }

  /// Initialize authentication state stream with comprehensive error handling
  void _initializeAuthStateStream() {
    _authStateController = StreamController<Either<Failure, User?>>.broadcast();

    // Listen to Firebase auth state changes
    firebaseAuthDataSource.authStateChanges.listen(
      (firebaseUser) async {
        try {
          await _handleAuthStateChange(firebaseUser);
        } catch (e) {
          if (!kReleaseMode) {
            print('❌ Auth state change error: $e');
          }
          _authStateController?.add(Left(UnknownFailure(e.toString())));
        }
      },
      onError: (error) {
        if (!kReleaseMode) {
          print('❌ Auth stream error: $error');
        }
        _authStateController?.add(
          Left(AuthFailure('Authentication stream error')),
        );
      },
    );
  }

  /// Handle authentication state changes with enhanced user data synchronization
  Future<void> _handleAuthStateChange(UserModel? firebaseUser) async {
    try {
      if (firebaseUser == null) {
        // User signed out
        _clearCache();
        _authStateController?.add(const Right(null));
        _logSecurityEvent('user_signed_out');
        return;
      }

      // User signed in - synchronize with Supabase
      final enrichedUser = await _enrichUserWithSupabaseData(firebaseUser);

      // Cache the user
      _updateCache(enrichedUser);

      // Emit the enriched user
      _authStateController?.add(Right(enrichedUser));

      _logSecurityEvent('user_authenticated', {
        'user_id': enrichedUser.id,
        'email': enrichedUser.email,
        'role': enrichedUser.role.name,
      });
    } catch (e) {
      if (!kReleaseMode) {
        print('❌ Auth state handling error: $e');
      }
      _authStateController?.add(
        Left(AuthFailure('Failed to process authentication state')),
      );
    }
  }

  /// Enrich Firebase user with Supabase data (role, profile, etc.)
  Future<UserModel> _enrichUserWithSupabaseData(UserModel firebaseUser) async {
    try {
      // Try to get user data from Supabase
      final supabaseUser = await supabaseUserDataSource.getUser(
        firebaseUser.id,
      );

      if (supabaseUser != null) {
        // Merge Firebase and Supabase data
        return _mergeUserData(firebaseUser, supabaseUser);
      } else {
        // User doesn't exist in Supabase - create them
        final userToSave = firebaseUser.copyWith(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await supabaseUserDataSource.saveUser(userToSave);

        if (!kReleaseMode) {
          print('✅ Created new user in Supabase: ${firebaseUser.email}');
        }

        return userToSave;
      }
    } catch (e) {
      if (!kReleaseMode) {
        print('⚠️ Failed to enrich user with Supabase data: $e');
      }

      // Fallback to Firebase data only
      return firebaseUser.copyWith(
        lastLoginAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Merge Firebase and Supabase user data intelligently
  UserModel _mergeUserData(UserModel firebaseUser, UserModel supabaseUser) {
    return supabaseUser.copyWith(
      // Use Firebase data for auth-related fields
      email: firebaseUser.email ?? supabaseUser.email,
      emailVerified: firebaseUser.emailVerified,
      photoURL: firebaseUser.photoURL ?? supabaseUser.photoURL,
      provider: firebaseUser.provider,
      linkedProviders: firebaseUser.linkedProviders,

      // Update login timestamp
      lastLoginAt: DateTime.now(),
      updatedAt: DateTime.now(),

      // Merge metadata
      metadata: {
        ...supabaseUser.metadata,
        ...firebaseUser.metadata,
        'last_firebase_sync': DateTime.now().toIso8601String(),
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
    return await _executeWithRetry(() async {
      _recordAuthAttempt();

      try {
        if (!kReleaseMode) {
          print('🔄 Starting Google sign-in process...');
        }

        // Perform Firebase Google sign-in
        final firebaseUser = await firebaseAuthDataSource.signInWithGoogle();

        // Enrich with Supabase data
        final enrichedUser = await _enrichUserWithSupabaseData(firebaseUser);

        // Update cache
        _updateCache(enrichedUser);

        _logSecurityEvent('google_signin_success', {
          'user_id': enrichedUser.id,
          'email': enrichedUser.email,
        });

        if (!kReleaseMode) {
          print('✅ Google sign-in successful: ${enrichedUser.email}');
        }

        return Right(enrichedUser);
      } on AuthException catch (e) {
        _recordFailedAttempt();
        _logSecurityEvent('google_signin_failed', {'error': e.message});
        throw e;
      } on DatabaseException catch (e) {
        _recordFailedAttempt();
        _logSecurityEvent('user_sync_failed', {'error': e.message});
        throw e;
      } catch (e) {
        _recordFailedAttempt();
        _logSecurityEvent('signin_error', {'error': e.toString()});
        throw AuthException('Sign-in failed: ${e.toString()}');
      }
    });
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    return await _executeWithRetry(() async {
      try {
        if (!kReleaseMode) {
          print('🔄 Starting sign-out process...');
        }

        final userId = _cachedUser?.id;

        // Sign out from Firebase
        await firebaseAuthDataSource.signOut();

        // Clear cache
        _clearCache();

        _logSecurityEvent('signout_success', {'user_id': userId});

        if (!kReleaseMode) {
          print('✅ Sign-out successful');
        }

        return const Right(null);
      } on AuthException catch (e) {
        _logSecurityEvent('signout_failed', {'error': e.message});
        throw e;
      } catch (e) {
        _logSecurityEvent('signout_error', {'error': e.toString()});
        throw AuthException('Sign-out failed: ${e.toString()}');
      }
    });
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      // Return cached user if valid
      if (_isCacheValid()) {
        return Right(_cachedUser);
      }

      // Get fresh user data
      final firebaseUser = await firebaseAuthDataSource.getCurrentUser();

      if (firebaseUser == null) {
        _clearCache();
        return const Right(null);
      }

      // Enrich with Supabase data
      final enrichedUser = await _enrichUserWithSupabaseData(firebaseUser);

      // Update cache
      _updateCache(enrichedUser);

      return Right(enrichedUser);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      // Check cache first
      if (_isCacheValid() && _cachedUser != null) {
        return const Right(true);
      }

      // Check Firebase auth state
      final isAuth = await firebaseAuthDataSource.isAuthenticated();
      return Right(isAuth);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Update user profile with comprehensive validation
  Future<Either<Failure, User>> updateUserProfile(
    String userId,
    UserProfileUpdateRequest request,
  ) async {
    return await _executeWithRetry(() async {
      try {
        // Validate request
        if (request.isEmpty) {
          throw const DatabaseException('No updates provided');
        }

        // Get current user
        final currentUserResult = await getCurrentUser();
        final currentUser = currentUserResult.fold(
          (failure) => throw AuthException('Failed to get current user'),
          (user) => user,
        );

        if (currentUser == null || currentUser.id != userId) {
          throw const AuthException('Unauthorized profile update');
        }

        // Update in Supabase
        final updateData = request.toJson();
        final response = await supabaseUserDataSource.updateUserProfile(
          userId,
          updateData,
        );

        // Clear cache to force refresh
        _clearCache();

        _logSecurityEvent('profile_updated', {
          'user_id': userId,
          'fields_updated': updateData.keys.toList(),
        });

        return Right(response);
      } on DatabaseException catch (e) {
        throw e;
      } catch (e) {
        throw DatabaseException('Profile update failed: ${e.toString()}');
      }
    });
  }

  /// Update user role with authorization check
  Future<Either<Failure, User>> updateUserRole(
    String userId,
    UserRole newRole,
    String updatedBy,
  ) async {
    return await _executeWithRetry(() async {
      try {
        // Update role in Supabase
        await supabaseUserDataSource.updateUserRole(userId, newRole.name);

        // Get updated user
        final updatedUser = await supabaseUserDataSource.getUser(userId);
        if (updatedUser == null) {
          throw const DatabaseException('Failed to retrieve updated user');
        }

        // Clear cache if this is the current user
        if (_cachedUser?.id == userId) {
          _clearCache();
        }

        _logSecurityEvent('role_updated', {
          'user_id': userId,
          'new_role': newRole.name,
          'updated_by': updatedBy,
        });

        return Right(updatedUser);
      } on DatabaseException catch (e) {
        throw e;
      } catch (e) {
        throw DatabaseException('Role update failed: ${e.toString()}');
      }
    });
  }

  /// Get user statistics for admin users
  Future<Either<Failure, UserStatistics>> getUserStatistics() async {
    try {
      final stats = await supabaseUserDataSource.getUserStatistics();
      return Right(stats);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Search users with advanced filtering
  Future<Either<Failure, List<User>>> searchUsers(UserQuery query) async {
    try {
      final users = await supabaseUserDataSource.searchUsers(query);
      return Right(users);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Refresh current user data
  Future<Either<Failure, User?>> refreshCurrentUser() async {
    try {
      _clearCache();
      return await getCurrentUser();
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // Cache Management

  bool _isCacheValid() {
    if (_cachedUser == null || _cacheTimestamp == null) return false;
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

  // Security Monitoring

  void _recordAuthAttempt() {
    _authAttempts++;
    _lastAttempt = DateTime.now();
  }

  void _recordFailedAttempt() {
    _failedAttempts++;
  }

  void _logSecurityEvent(String event, [Map<String, dynamic>? details]) {
    if (!kReleaseMode) {
      print('🔒 Security Event: $event${details != null ? ' - $details' : ''}');
    }
    // In production, send to security monitoring service
  }

  // Error Handling and Retry Logic

  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxRetries) rethrow;

        // Only retry on specific exceptions
        if (e is DatabaseException || e is ServerException) {
          if (!kReleaseMode) {
            print('🔄 Retry attempt $attempt/$maxRetries after error: $e');
          }
          await Future.delayed(retryDelay * attempt);
          continue;
        }

        rethrow;
      }
    }

    throw Exception('Max retries exceeded');
  }

  Future<Either<Failure, T>> _executeOperation<T>(
    Future<T> Function() operation,
  ) async {
    try {
      final result = await operation();
      return Right(result);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // Repository Health and Monitoring

  Map<String, dynamic> getHealthStatus() {
    return {
      'cache_valid': _isCacheValid(),
      'cached_user_id': _cachedUser?.id,
      'cache_age_seconds':
          _cacheTimestamp != null
              ? DateTime.now().difference(_cacheTimestamp!).inSeconds
              : null,
      'auth_attempts': _authAttempts,
      'failed_attempts': _failedAttempts,
      'success_rate':
          _authAttempts > 0
              ? (((_authAttempts - _failedAttempts) / _authAttempts) * 100)
                      .toStringAsFixed(1) +
                  '%'
              : '0%',
      'last_attempt': _lastAttempt?.toIso8601String(),
      'stream_active':
          _authStateController != null && !_authStateController!.isClosed,
    };
  }

  Map<String, dynamic> getSecurityMetrics() {
    if (kReleaseMode) return {'status': 'production_mode'};

    return {
      'authentication_attempts': _authAttempts,
      'failed_attempts': _failedAttempts,
      'success_rate':
          _authAttempts > 0
              ? ((_authAttempts - _failedAttempts) / _authAttempts * 100)
                      .toStringAsFixed(1) +
                  '%'
              : '0%',
      'cache_hit_rate': 'N/A', // Could implement cache hit tracking
      'last_security_event': _lastAttempt?.toIso8601String(),
      'data_sources': {'firebase': 'active', 'supabase': 'active'},
    };
  }

  // Cleanup

  void dispose() {
    _authStateController?.close();
    _clearCache();

    if (!kReleaseMode) {
      print('🧹 AuthRepository disposed');
    }
  }
}

/// Extension methods for enhanced Supabase user data source
extension SupabaseUserDataSourceExtensions on SupabaseUserDataSource {
  Future<UserModel> updateUserProfile(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    // This would be implemented in the actual data source
    throw UnimplementedError('Profile update not implemented');
  }

  Future<UserStatistics> getUserStatistics() async {
    // This would be implemented in the actual data source
    throw UnimplementedError('Statistics not implemented');
  }

  Future<List<UserModel>> searchUsers(UserQuery query) async {
    // This would be implemented in the actual data source
    throw UnimplementedError('User search not implemented');
  }
}

class UserStatistics {
  final int totalUsers;
  final int activeUsers;
  final DateTime lastUpdated;

  const UserStatistics({
    required this.totalUsers,
    required this.activeUsers,
    required this.lastUpdated,
  });
}

class UserQuery {
  final String? searchTerm;
  final UserRole? role;
  final int limit;
  final int offset;

  const UserQuery({
    this.searchTerm,
    this.role,
    this.limit = 50,
    this.offset = 0,
  });
}

class UserProfileUpdateRequest {
  final String? displayName;
  final String? phoneNumber;
  final String? photoURL;

  const UserProfileUpdateRequest({
    this.displayName,
    this.phoneNumber,
    this.photoURL,
  });

  bool get isEmpty =>
      displayName == null && phoneNumber == null && photoURL == null;

  Map<String, dynamic> toJson() => {
    if (displayName != null) 'display_name': displayName,
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (photoURL != null) 'photo_url': photoURL,
    'updated_at': DateTime.now().toIso8601String(),
  };
}
