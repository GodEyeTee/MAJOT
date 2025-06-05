import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/security_settings.dart';

abstract class SecurityRepository {
  Future<Either<Failure, SecuritySettings>> getSecuritySettings(String userId);
  Future<Either<Failure, void>> updateSecuritySettings(
    SecuritySettings settings,
  );
  Future<Either<Failure, void>> enableTwoFactor(String userId);
  Future<Either<Failure, void>> disableTwoFactor(String userId);
  Future<Either<Failure, void>> changePassword(
    String currentPassword,
    String newPassword,
  );
  Future<Either<Failure, void>> revokeDevice(String deviceId);
  Future<Either<Failure, List<LoginHistory>>> getLoginHistory(String userId);
}
