// lib/core/themes/theme_extensions.dart
import 'package:flutter/material.dart';

extension ThemeExtensions on BuildContext {
  // Typography shortcuts
  AppTypography get typography => AppTypography(this);

  // Custom colors shortcuts
  CustomColors get customColors => CustomColors(this);
}

class AppTypography {
  final BuildContext context;

  AppTypography(this.context);

  TextTheme get _textTheme => Theme.of(context).textTheme;

  TextStyle? get h1 => _textTheme.displayLarge;
  TextStyle? get h2 => _textTheme.displayMedium;
  TextStyle? get h3 => _textTheme.displaySmall;
  TextStyle? get h4 => _textTheme.headlineMedium;
  TextStyle? get h5 => _textTheme.headlineSmall;
  TextStyle? get h6 => _textTheme.titleLarge;

  TextStyle? get subtitle1 => _textTheme.titleMedium;
  TextStyle? get subtitle2 => _textTheme.titleSmall;

  TextStyle? get body1 => _textTheme.bodyLarge;
  TextStyle? get body2 => _textTheme.bodyMedium;

  TextStyle? get button => _textTheme.labelLarge;
  TextStyle? get caption => _textTheme.bodySmall;
  TextStyle? get overline => _textTheme.labelSmall;
}

class CustomColors {
  final BuildContext context;

  CustomColors(this.context);

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;

  // Custom colors based on theme
  Color get success => Colors.green.shade600;
  Color get warning => Colors.orange.shade600;
  Color get danger => Colors.red.shade600;
  Color get info => Colors.blue.shade600;

  // Semantic colors
  Color get textPrimary => _colorScheme.onSurface;
  Color get textSecondary => _colorScheme.onSurface.withValues(alpha: 0.6);
  Color get textTertiary => _colorScheme.onSurface.withValues(alpha: 0.4);

  // Background variations
  Color get backgroundSecondary => _colorScheme.surfaceContainerHighest;
  Color get backgroundTertiary => _colorScheme.surfaceContainerHigh;

  // Border colors
  Color get border => _colorScheme.outline;
  Color get borderLight => _colorScheme.outlineVariant;
}
