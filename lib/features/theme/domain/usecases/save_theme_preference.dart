import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app_theme_mode.dart';
import '../repositories/theme_repository.dart';

class SaveThemePreference implements UseCase<void, AppThemeMode> {
  final ThemeRepository repository;

  SaveThemePreference(this.repository);

  @override
  Future<Either<Failure, void>> call(AppThemeMode mode) async {
    return await repository.saveThemePreference(mode);
  }
}
