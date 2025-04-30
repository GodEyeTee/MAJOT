import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_data_source.dart';
import '../datasources/supabase_user_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource firebaseAuthDataSource;
  final SupabaseUserDataSource supabaseUserDataSource;

  AuthRepositoryImpl({
    required this.firebaseAuthDataSource,
    required this.supabaseUserDataSource,
  });

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      // ทดสอบการเชื่อมต่อกับ Supabase ก่อน
      try {
        final user = await firebaseAuthDataSource.signInWithGoogle();
        try {
          await supabaseUserDataSource.saveUser(user);
          return Right(user);
        } catch (supabaseError) {
          // ถ้า Supabase มีปัญหา แต่เข้าสู่ระบบ Firebase ได้ ให้ทำงานต่อไป
          print('Warning: Failed to save user to Supabase: $supabaseError');
          return Right(user);
        }
      } catch (firebaseError) {
        return Left(AuthFailure('Authentication failed: $firebaseError'));
      }
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
      final user = firebaseAuthDataSource.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final result = firebaseAuthDataSource.isAuthenticated();
      return Right(result);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
