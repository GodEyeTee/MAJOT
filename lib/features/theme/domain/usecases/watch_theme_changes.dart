import '../entities/app_theme_mode.dart';
import '../repositories/theme_repository.dart';

class WatchThemeChanges {
  final ThemeRepository repository;

  WatchThemeChanges(this.repository);

  Stream<AppThemeMode> call() {
    return repository.watchThemeChanges();
  }
}
