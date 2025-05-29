import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_data_source.dart';
import '../datasources/supabase_user_data_source.dart';
import '../models/user_model.dart';
import '../../../../services/rbac/role_manager.dart';
import 'dart:async';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource firebaseAuthDataSource;
  final SupabaseUserDataSource supabaseUserDataSource;

  UserModel? _cachedUser;
  DateTime? _cacheTimestamp;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  StreamController<Either<Failure, User?>>? _authStateController;

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
          print('❌ Auth state change error: $e');
          _authStateController?.add(Left(UnknownFailure(e.toString())));
        }
      },
      onError: (error) {
        print('❌ Auth stream error: $error');
        _authStateController?.add(
          Left(AuthFailure('Authentication stream error')),
        );
      },
    );
  }

  Future<void> _handleAuthStateChange(UserModel? firebaseUser) async {
    try {
      print('🔄 Handling auth state change...');

      if (firebaseUser == null) {
        print('❌ No Firebase user - clearing cache and signaling signed out');
        _clearCache();
        _authStateController?.add(const Right(null));
        return;
      }

      print('✅ Firebase user found: ${firebaseUser.email}');
      final enrichedUser = await _enrichUserWithSupabaseData(firebaseUser);
      _updateCache(enrichedUser);
      _authStateController?.add(Right(enrichedUser));
    } catch (e) {
      print('❌ Error handling auth state change: $e');
      _authStateController?.add(
        Left(AuthFailure('Failed to process authentication state')),
      );
    }
  }

  Future<UserModel> _enrichUserWithSupabaseData(UserModel firebaseUser) async {
    try {
      print('🔄 Enriching Firebase user with Supabase data...');
      print(
        '   Firebase user: ${firebaseUser.email} (role: ${firebaseUser.role})',
      );

      final supabaseUser = await supabaseUserDataSource.getUser(
        firebaseUser.id,
      );

      if (supabaseUser != null) {
        print('✅ Found existing Supabase user');
        print('   Supabase role: ${supabaseUser.role}');
        return _mergeUserData(firebaseUser, supabaseUser);
      } else {
        print('⚠️ No existing Supabase user found - creating new one');
        final userToSave = firebaseUser.copyWith(
          role: UserRole.user, // Default role for new users
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        print('📝 Saving new user to Supabase with role: ${userToSave.role}');
        await supabaseUserDataSource.saveUser(userToSave);
        return userToSave;
      }
    } catch (e) {
      print('❌ Error enriching user data: $e');
      return firebaseUser.copyWith(
        lastLoginAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  UserModel _mergeUserData(UserModel firebaseUser, UserModel supabaseUser) {
    print('🔄 Merging user data:');
    print('   Firebase email: ${firebaseUser.email}');
    print('   Firebase role: ${firebaseUser.role}');
    print('   Supabase email: ${supabaseUser.email}');
    print('   Supabase role: ${supabaseUser.role}');
    print('   Supabase role source: ${supabaseUser.metadata['role_source']}');

    final mergedUser = supabaseUser.copyWith(
      email: firebaseUser.email ?? supabaseUser.email,
      emailVerified: firebaseUser.emailVerified,
      photoURL: firebaseUser.photoURL ?? supabaseUser.photoURL,
      provider: firebaseUser.provider,
      linkedProviders: firebaseUser.linkedProviders,
      lastLoginAt: DateTime.now(),
      updatedAt: DateTime.now(),
      // Use role from Supabase as primary source
      role: supabaseUser.role,
      metadata: {
        ...supabaseUser.metadata,
        ...firebaseUser.metadata,
        'last_firebase_sync': DateTime.now().toIso8601String(),
        'role_source': 'supabase_merged',
        'merge_timestamp': DateTime.now().toIso8601String(),
      },
    );

    print('✅ Merged user data:');
    print('   Final email: ${mergedUser.email}');
    print('   Final role: ${mergedUser.role}');
    print('   Role source: ${mergedUser.metadata['role_source']}');

    return mergedUser;
  }

  @override
  Stream<Either<Failure, User?>> get authStateChanges {
    return _authStateController?.stream ??
        Stream.value(const Left(AuthFailure('Auth stream not initialized')));
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      print('🔄 Starting Google sign-in process...');
      final firebaseUser = await firebaseAuthDataSource.signInWithGoogle();
      final enrichedUser = await _enrichUserWithSupabaseData(firebaseUser);
      _updateCache(enrichedUser);
      print('✅ Google sign-in completed with role: ${enrichedUser.role}');
      return Right(enrichedUser);
    } on AuthException catch (e) {
      print('❌ Auth exception during sign-in: ${e.message}');
      return Left(AuthFailure(e.message));
    } on DatabaseException catch (e) {
      print('❌ Database exception during sign-in: ${e.message}');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      print('❌ Unknown error during sign-in: $e');
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      print('🔄 Starting sign-out process...');
      await firebaseAuthDataSource.signOut();
      _clearCache();
      print('✅ Sign-out completed');
      return const Right(null);
    } on AuthException catch (e) {
      print('❌ Auth exception during sign-out: ${e.message}');
      return Left(AuthFailure(e.message));
    } catch (e) {
      print('❌ Unknown error during sign-out: $e');
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      print('🔄 Getting current user...');

      // Check cache first
      if (_isCacheValid() && _cachedUser != null) {
        print(
          '✅ Using cached user: ${_cachedUser!.email} (role: ${_cachedUser!.role})',
        );
        return Right(_cachedUser);
      }

      print('📋 Cache invalid or empty - fetching fresh data');
      final firebaseUser = await firebaseAuthDataSource.getCurrentUser();
      if (firebaseUser == null) {
        print('❌ No Firebase user found');
        _clearCache();
        return const Right(null);
      }

      final enrichedUser = await _enrichUserWithSupabaseData(firebaseUser);
      _updateCache(enrichedUser);
      print(
        '✅ Got current user: ${enrichedUser.email} (role: ${enrichedUser.role})',
      );
      return Right(enrichedUser);
    } on AuthException catch (e) {
      print('❌ Auth exception: ${e.message}');
      return Left(AuthFailure(e.message));
    } on DatabaseException catch (e) {
      print('❌ Database exception: ${e.message}');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      print('❌ Unknown error: $e');
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<Either<Failure, User?>> forceGetCurrentUser() async {
    try {
      print('🔄 FORCE REFRESH: Starting complete user data refresh...');

      // Clear ALL caches
      print('🧹 Clearing all caches...');
      _clearCache();

      // Clear Firebase cache if available
      if (firebaseAuthDataSource is FirebaseAuthDataSourceImpl) {
        (firebaseAuthDataSource as FirebaseAuthDataSourceImpl)
            .forceClearCache();
        print('✅ Firebase cache cleared');
      }

      // Force get fresh Firebase user
      print('🔥 Getting fresh Firebase user...');
      final firebaseUser = await firebaseAuthDataSource.getCurrentUser();
      if (firebaseUser == null) {
        print('❌ No Firebase user found after force refresh');
        return const Right(null);
      }

      print(
        '✅ Got fresh Firebase user: ${firebaseUser.email} (role: ${firebaseUser.role})',
      );

      // Force get fresh Supabase data
      print('🔥 Getting fresh Supabase user data for ID: ${firebaseUser.id}');
      final supabaseUser = await supabaseUserDataSource.getUser(
        firebaseUser.id,
      );

      UserModel enrichedUser;
      if (supabaseUser != null) {
        print('✅ Got fresh Supabase user data:');
        print('   ID: ${supabaseUser.id}');
        print('   Email: ${supabaseUser.email}');
        print('   Role: ${supabaseUser.role}');
        print('   Role source: ${supabaseUser.metadata['role_source']}');

        enrichedUser = _mergeUserData(firebaseUser, supabaseUser);
      } else {
        print('⚠️ No Supabase user found - creating new one');
        final userToSave = firebaseUser.copyWith(
          role: UserRole.user, // Default role for new users
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        print('📝 Saving new user with role: ${userToSave.role}');
        await supabaseUserDataSource.saveUser(userToSave);
        enrichedUser = userToSave;
      }

      // Update cache with fresh data
      _updateCache(enrichedUser);

      print('🎉 FORCE REFRESH COMPLETED:');
      print('   User: ${enrichedUser.email}');
      print('   Role: ${enrichedUser.role}');
      print(
        '   Permissions: ${RoleManager().getPermissionsForRole(enrichedUser.role).map((p) => p.id).join(', ')}',
      );

      return Right(enrichedUser);
    } on AuthException catch (e) {
      print('❌ Auth error during force refresh: ${e.message}');
      return Left(AuthFailure(e.message));
    } on DatabaseException catch (e) {
      print('❌ Database error during force refresh: ${e.message}');
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      print('❌ Unknown error during force refresh: $e');
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
      print(
        '📋 Cache invalid: ${_cachedUser == null ? 'no user' : 'no timestamp'}',
      );
      return false;
    }

    final age = DateTime.now().difference(_cacheTimestamp!);
    final isValid = age < _cacheValidityDuration;

    print('📋 Cache age: ${age.inMinutes}min, valid: $isValid');
    return isValid;
  }

  void _updateCache(UserModel user) {
    _cachedUser = user;
    _cacheTimestamp = DateTime.now();
    print('✅ Cache updated: ${user.email} (role: ${user.role})');
  }

  void _clearCache() {
    final hadUser = _cachedUser != null;
    _cachedUser = null;
    _cacheTimestamp = null;
    if (hadUser) {
      print('🧹 Cache cleared');
    }
  }

  void dispose() {
    _authStateController?.close();
    _clearCache();
    print('🧹 AuthRepositoryImpl disposed');
  }
}
