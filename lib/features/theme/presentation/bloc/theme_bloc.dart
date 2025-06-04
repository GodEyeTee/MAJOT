import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/usecases/get_theme_preference.dart';
import '../../domain/usecases/save_theme_preference.dart';
import '../../domain/usecases/watch_theme_changes.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final GetThemePreference getThemePreference;
  final SaveThemePreference saveThemePreference;
  final WatchThemeChanges watchThemeChanges;

  ThemeBloc({
    required this.getThemePreference,
    required this.saveThemePreference,
    required this.watchThemeChanges,
  }) : super(ThemeInitial()) {
    on<LoadThemeEvent>(_onLoadTheme);
    on<ChangeThemeEvent>(_onChangeTheme);

    // Auto-load theme on initialization
    add(LoadThemeEvent());
  }

  Future<void> _onLoadTheme(
    LoadThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    emit(ThemeLoading());

    final result = await getThemePreference(const NoParams());

    result.fold((failure) => emit(ThemeError(failure.message)), (preference) {
      final actualMode = _getActualThemeMode(preference.mode);
      emit(
        ThemeLoaded(themeMode: preference.mode, actualThemeMode: actualMode),
      );
    });
  }

  Future<void> _onChangeTheme(
    ChangeThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    final result = await saveThemePreference(event.themeMode);

    result.fold((failure) => emit(ThemeError(failure.message)), (_) {
      final actualMode = _getActualThemeMode(event.themeMode);
      emit(
        ThemeLoaded(themeMode: event.themeMode, actualThemeMode: actualMode),
      );
    });
  }

  ThemeMode _getActualThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        // Check system brightness
        final brightness =
            SchedulerBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    }
  }
}
