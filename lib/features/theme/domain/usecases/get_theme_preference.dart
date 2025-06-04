import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app_theme_mode.dart';
import '../repositories/theme_repository.dart';

class GetThemePreference implements UseCase<ThemePreference, NoParams> {
  final ThemeRepository repository;

  GetThemePreference(this.repository);

  @override
  Future<Either<Failure, ThemePreference>> call(NoParams params) async {
    return await repository.getThemePreference();
  }
}
