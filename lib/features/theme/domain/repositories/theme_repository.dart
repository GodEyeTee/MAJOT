import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_theme_mode.dart';

abstract class ThemeRepository {
  Future<Either<Failure, ThemePreference>> getThemePreference();
  Future<Either<Failure, void>> saveThemePreference(AppThemeMode mode);
  Stream<AppThemeMode> watchThemeChanges();
}
