import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/themes/app_spacing.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../bloc/theme_bloc.dart';
import '../bloc/theme_event.dart';
import '../bloc/theme_state.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        if (state is ThemeLoaded) {
          return _buildThemeOptions(context, state.themeMode);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildThemeOptions(BuildContext context, AppThemeMode currentMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Theme', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.verticalGapSm,
        ...AppThemeMode.values.map(
          (mode) => _buildThemeOption(context, mode, currentMode == mode),
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    AppThemeMode mode,
    bool isSelected,
  ) {
    return RadioListTile<AppThemeMode>(
      title: Text(mode.displayName),
      subtitle: Text(mode.description),
      value: mode,
      groupValue: isSelected ? mode : null,
      onChanged: (_) {
        context.read<ThemeBloc>().add(ChangeThemeEvent(mode));
      },
      secondary: Icon(_getThemeIcon(mode)),
    );
  }

  IconData _getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.settings_brightness;
    }
  }
}

class ThemeSelectorDialog extends StatelessWidget {
  const ThemeSelectorDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ThemeSelectorDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        if (state is ThemeLoaded) {
          return AlertDialog(
            title: const Text('Choose Theme'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  AppThemeMode.values.map((mode) {
                    return ListTile(
                      leading: Icon(_getThemeIcon(mode)),
                      title: Text(mode.displayName),
                      subtitle: Text(mode.description),
                      selected: state.themeMode == mode,
                      onTap: () {
                        context.read<ThemeBloc>().add(ChangeThemeEvent(mode));
                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  IconData _getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.settings_brightness;
    }
  }
}

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        if (state is ThemeLoaded) {
          return IconButton(
            icon: Icon(_getThemeIcon(state.themeMode)),
            onPressed: () => ThemeSelectorDialog.show(context),
            tooltip: 'Change theme',
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  IconData _getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.settings_brightness;
    }
  }
}
