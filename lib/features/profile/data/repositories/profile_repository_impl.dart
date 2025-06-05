import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Profile>> getProfile(String userId) async {
    try {
      final profile = await remoteDataSource.getProfile(userId);
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Profile>> updateProfile(Profile profile) async {
    try {
      final profileModel = ProfileModel(
        userId: profile.userId,
        displayName: profile.displayName,
        email: profile.email,
        photoUrl: profile.photoUrl,
        bio: profile.bio,
        phoneNumber: profile.phoneNumber,
        dateOfBirth: profile.dateOfBirth,
        preferences: profile.preferences,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      );

      final updatedProfile = await remoteDataSource.updateProfile(profileModel);
      return Right(updatedProfile);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfilePhoto(
    String userId,
    String imagePath,
  ) async {
    try {
      final url = await remoteDataSource.uploadProfilePhoto(userId, imagePath);
      return Right(url);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProfilePhoto(String userId) async {
    try {
      await remoteDataSource.deleteProfilePhoto(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
