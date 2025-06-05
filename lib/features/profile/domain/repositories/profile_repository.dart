import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, Profile>> getProfile(String userId);
  Future<Either<Failure, Profile>> updateProfile(Profile profile);
  Future<Either<Failure, String>> uploadProfilePhoto(
    String userId,
    String imagePath,
  );
  Future<Either<Failure, void>> deleteProfilePhoto(String userId);
}
