import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/exceptions.dart';

abstract class ThemeLocalDataSource {
  Future<String> getThemeMode();
  Future<void> saveThemeMode(String mode);
  Stream<String> watchThemeMode();
}

class ThemeLocalDataSourceImpl implements ThemeLocalDataSource {
  static const String _themeKey = 'theme_mode';
  static const String _defaultTheme = 'system';

  final SharedPreferences sharedPreferences;

  ThemeLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<String> getThemeMode() async {
    try {
      final mode = sharedPreferences.getString(_themeKey);
      return mode ?? _defaultTheme;
    } catch (e) {
      throw CacheException('Failed to get theme mode: $e');
    }
  }

  @override
  Future<void> saveThemeMode(String mode) async {
    try {
      final success = await sharedPreferences.setString(_themeKey, mode);
      if (!success) {
        throw CacheException('Failed to save theme mode');
      }
    } catch (e) {
      throw CacheException('Failed to save theme mode: $e');
    }
  }

  @override
  Stream<String> watchThemeMode() async* {
    // Initial value
    yield await getThemeMode();

    // In a real app, you might use a stream controller or reactive storage
    // For now, we'll just emit the current value
    // You could enhance this with proper stream management
  }
}
