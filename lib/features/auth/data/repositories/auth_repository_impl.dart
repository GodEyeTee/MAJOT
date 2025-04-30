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
      final user = await firebaseAuthDataSource.signInWithGoogle();
      await supabaseUserDataSource.saveUser(user);
      return Right(user);
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
