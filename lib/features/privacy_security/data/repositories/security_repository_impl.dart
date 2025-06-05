import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/security_settings.dart';
import '../../domain/repositories/security_repository.dart';
import '../datasources/security_remote_data_source.dart';
import '../models/security_settings_model.dart';

class SecurityRepositoryImpl implements SecurityRepository {
  final SecurityRemoteDataSource remoteDataSource;

  SecurityRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, SecuritySettings>> getSecuritySettings(
    String userId,
  ) async {
    try {
      final settings = await remoteDataSource.getSecuritySettings(userId);
      return Right(settings);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSecuritySettings(
    SecuritySettings settings,
  ) async {
    try {
      final model = SecuritySettingsModel(
        userId: settings.userId,
        twoFactorEnabled: settings.twoFactorEnabled,
        biometricEnabled: settings.biometricEnabled,
        lastPasswordChange: settings.lastPasswordChange,
        loginHistory: settings.loginHistory,
        connectedDevices: settings.connectedDevices,
        privacyPreferences: settings.privacyPreferences,
      );

      await remoteDataSource.updateSecuritySettings(model);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> enableTwoFactor(String userId) async {
    try {
      // Implementation for 2FA
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disableTwoFactor(String userId) async {
    try {
      // Implementation for 2FA
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      // Implementation for password change
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> revokeDevice(String deviceId) async {
    try {
      await remoteDataSource.revokeDevice(deviceId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LoginHistory>>> getLoginHistory(
    String userId,
  ) async {
    try {
      final history = await remoteDataSource.getLoginHistory(userId);
      return Right(history);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
