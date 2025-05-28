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
  Stream<Either<Failure, User?>> get authStateChanges {
    return firebaseAuthDataSource.authStateChanges
        .asyncMap<Either<Failure, User?>>((firebaseUser) async {
          if (firebaseUser == null) {
            return const Right(null);
          }

          try {
            // พยายามดึงข้อมูลจาก Supabase เพื่อให้ได้ complete user data พร้อม role
            final supabaseUser = await supabaseUserDataSource.getUser(
              firebaseUser.id,
            );
            final User? finalUser = supabaseUser ?? firebaseUser;
            return Right(finalUser);
          } catch (supabaseError) {
            print('Warning: Failed to get user from Supabase: $supabaseError');
            // ถ้า Supabase มีปัญหา ให้ใช้ข้อมูลจาก Firebase
            return Right(firebaseUser);
          }
        })
        .handleError((error) {
          return Left(UnknownFailure(error.toString()));
        });
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final firebaseUser = await firebaseAuthDataSource.signInWithGoogle();

      try {
        // บันทึกข้อมูลลง Supabase
        await supabaseUserDataSource.saveUser(firebaseUser);

        // ดึงข้อมูลรวม role กลับมาจาก Supabase
        final supabaseUser = await supabaseUserDataSource.getUser(
          firebaseUser.id,
        );

        // ถ้าได้ข้อมูลจาก Supabase ให้ใช้ข้อมูลนั้น (มี role)
        // ถ้าไม่ได้ให้ใช้ข้อมูลจาก Firebase (role เป็น user)
        final finalUser = supabaseUser ?? firebaseUser;

        return Right(finalUser);
      } catch (supabaseError) {
        print('Warning: Failed to save/get user from Supabase: $supabaseError');
        // ถ้า Supabase มีปัญหา ให้ใช้ข้อมูลจาก Firebase เพียงอย่างเดียว
        return Right(firebaseUser);
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
      final firebaseUser = await firebaseAuthDataSource.getCurrentUser();
      if (firebaseUser == null) {
        return const Right(null);
      }

      try {
        // พยายามดึงข้อมูลจาก Supabase เพื่อให้ได้ role
        final supabaseUser = await supabaseUserDataSource.getUser(
          firebaseUser.id,
        );
        final finalUser = supabaseUser ?? firebaseUser;
        return Right(finalUser);
      } catch (supabaseError) {
        print('Warning: Failed to get user from Supabase: $supabaseError');
        // ถ้า Supabase มีปัญหา ให้ใช้ข้อมูลจาก Firebase
        return Right(firebaseUser);
      }
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final result = await firebaseAuthDataSource.isAuthenticated();
      return Right(result);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
