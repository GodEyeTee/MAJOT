import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_data_source.dart';
import '../datasources/supabase_user_data_source.dart';
import '../models/user_model.dart';
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
          _authStateController?.add(Left(UnknownFailure(e.toString())));
        }
      },
      onError: (error) {
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

      final enrichedUser = await _enrichUserWithSupabaseData(firebaseUser);
      _updateCache(enrichedUser);
      _authStateController?.add(Right(enrichedUser));
    } catch (e) {
      _authStateController?.add(
        Left(AuthFailure('Failed to process authentication state')),
      );
    }
  }

  Future<UserModel> _enrichUserWithSupabaseData(UserModel firebaseUser) async {
    try {
      final supabaseUser = await supabaseUserDataSource.getUser(
        firebaseUser.id,
      );

      if (supabaseUser != null) {
        return _mergeUserData(firebaseUser, supabaseUser);
      } else {
        final userToSave = firebaseUser.copyWith(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        await supabaseUserDataSource.saveUser(userToSave);
        return userToSave;
      }
    } catch (e) {
      return firebaseUser.copyWith(
        lastLoginAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  UserModel _mergeUserData(UserModel firebaseUser, UserModel supabaseUser) {
    print('🔄 Merging user data:');
    print('   Firebase role: ${firebaseUser.role}');
    print('   Supabase role: ${supabaseUser.role}');

    final mergedUser = supabaseUser.copyWith(
      email: firebaseUser.email ?? supabaseUser.email,
      emailVerified: firebaseUser.emailVerified,
      photoURL: firebaseUser.photoURL ?? supabaseUser.photoURL,
      provider: firebaseUser.provider,
      linkedProviders: firebaseUser.linkedProviders,
      lastLoginAt: DateTime.now(),
      updatedAt: DateTime.now(),
      // ใช้ role จาก Supabase เป็นหลัก แทนที่จะ merge
      role: supabaseUser.role, // ใช้ role จาก Supabase
      metadata: {
        ...supabaseUser.metadata,
        ...firebaseUser.metadata,
        'last_firebase_sync': DateTime.now().toIso8601String(),
        'role_source': 'supabase',
      },
    );

    print('   Final merged role: ${mergedUser.role}');
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
      final firebaseUser = await firebaseAuthDataSource.signInWithGoogle();
      final enrichedUser = await _enrichUserWithSupabaseData(firebaseUser);
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
  Future<Either<Failure, void>> signOut() async {
    try {
      await firebaseAuthDataSource.signOut();
      _clearCache();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      // ใช้ cache ตามปกติ
      if (_isCacheValid() && _cachedUser != null) {
        return Right(_cachedUser);
      }

      final firebaseUser = await firebaseAuthDataSource.getCurrentUser();
      if (firebaseUser == null) {
        _clearCache();
        return const Right(null);
      }

      final enrichedUser = await _enrichUserWithSupabaseData(firebaseUser);
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

  Future<Either<Failure, User?>> forceGetCurrentUser() async {
    try {
      print('🔄 Force refreshing user data from all sources...');

      // Clear all caches first
      _clearCache();

      // Clear Firebase auth cache
      if (firebaseAuthDataSource is FirebaseAuthDataSourceImpl) {
        (firebaseAuthDataSource as FirebaseAuthDataSourceImpl)
            .forceClearCache();
      }

      // Force get fresh Firebase user
      final firebaseUser = await firebaseAuthDataSource.getCurrentUser();
      if (firebaseUser == null) {
        print('❌ No Firebase user found');
        return const Right(null);
      }

      print(
        '✅ Got Firebase user: ${firebaseUser.email} (role: ${firebaseUser.role})',
      );

      // Force get fresh Supabase data
      print('🔄 Getting fresh data from Supabase for user: ${firebaseUser.id}');
      final supabaseUser = await supabaseUserDataSource.getUser(
        firebaseUser.id,
      );

      UserModel enrichedUser;
      if (supabaseUser != null) {
        print('✅ Got Supabase user data - role: ${supabaseUser.role}');
        enrichedUser = _mergeUserData(firebaseUser, supabaseUser);
        print('✅ Merged data - Final role: ${enrichedUser.role}');
      } else {
        print('⚠️ No Supabase user found, creating new one with guest role');
        // Save new user to Supabase with guest role
        final userToSave = firebaseUser.copyWith(
          role: UserRole.guest, // เริ่มต้นด้วย guest
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        await supabaseUserDataSource.saveUser(userToSave);
        enrichedUser = userToSave;
        print('✅ Created new user in Supabase with guest role');
      }

      // Update cache with fresh data
      _updateCache(enrichedUser);

      print('🎉 Force refresh completed - Final role: ${enrichedUser.role}');
      print(
        '🎉 User permissions will be: ${RoleManager().getPermissionsForRole(enrichedUser.role).map((p) => p.id).join(', ')}',
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

  void dispose() {
    _authStateController?.close();
    _clearCache();
  }
}
