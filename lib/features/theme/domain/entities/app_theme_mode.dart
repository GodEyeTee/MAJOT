import 'package:equatable/equatable.dart';

enum AppThemeMode { light, dark, system }

class ThemePreference extends Equatable {
  final AppThemeMode mode;
  final DateTime? lastModified;

  const ThemePreference({required this.mode, this.lastModified});

  @override
  List<Object?> get props => [mode, lastModified];
}

extension AppThemeModeExtension on AppThemeMode {
  String get name {
    switch (this) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }

  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }

  String get description {
    switch (this) {
      case AppThemeMode.light:
        return 'Always use light theme';
      case AppThemeMode.dark:
        return 'Always use dark theme';
      case AppThemeMode.system:
        return 'Follow system theme';
    }
  }
}
