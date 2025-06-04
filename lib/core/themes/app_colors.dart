import 'package:flutter/material.dart';

/// Custom color definitions for the app
class AppColors {
  // Light Theme Colors
  static const Color lightPrimary = Color(0xFF2196F3);
  static const Color lightPrimaryVariant = Color(0xFF1976D2);
  static const Color lightSecondary = Color(0xFF00BCD4);
  static const Color lightSecondaryVariant = Color(0xFF0097A7);
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Colors.white;
  static const Color lightError = Color(0xFFE91E63);
  static const Color lightOnPrimary = Colors.white;
  static const Color lightOnSecondary = Colors.white;
  static const Color lightOnBackground = Color(0xFF212121);
  static const Color lightOnSurface = Color(0xFF212121);
  static const Color lightOnError = Colors.white;

  // Dark Theme Colors
  static const Color darkPrimary = Color(0xFF64B5F6);
  static const Color darkPrimaryVariant = Color(0xFF42A5F5);
  static const Color darkSecondary = Color(0xFF4DD0E1);
  static const Color darkSecondaryVariant = Color(0xFF26C6DA);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkError = Color(0xFFFF5252);
  static const Color darkOnPrimary = Color(0xFF000000);
  static const Color darkOnSecondary = Color(0xFF000000);
  static const Color darkOnBackground = Color(0xFFE0E0E0);
  static const Color darkOnSurface = Color(0xFFE0E0E0);
  static const Color darkOnError = Color(0xFF000000);

  // Custom Colors (available in both themes)
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF03A9F4);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF2196F3),
    Color(0xFF1976D2),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF00BCD4),
    Color(0xFF0097A7),
  ];

  // Neutral Colors
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
}

/// Custom color scheme extension for additional colors
@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  final Color? success;
  final Color? warning;
  final Color? info;
  final Color? cardBackground;
  final Color? divider;
  final Color? shimmer;
  final Color? shadow;
  final Gradient? primaryGradient;
  final Gradient? secondaryGradient;

  const CustomColors({
    this.success,
    this.warning,
    this.info,
    this.cardBackground,
    this.divider,
    this.shimmer,
    this.shadow,
    this.primaryGradient,
    this.secondaryGradient,
  });

  // Light theme custom colors
  static const light = CustomColors(
    success: AppColors.success,
    warning: AppColors.warning,
    info: AppColors.info,
    cardBackground: Colors.white,
    divider: AppColors.grey300,
    shimmer: AppColors.grey100,
    shadow: Color(0x1F000000),
    primaryGradient: LinearGradient(
      colors: AppColors.primaryGradient,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    secondaryGradient: LinearGradient(
      colors: AppColors.secondaryGradient,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Dark theme custom colors
  static const dark = CustomColors(
    success: AppColors.success,
    warning: AppColors.warning,
    info: AppColors.info,
    cardBackground: AppColors.darkSurface,
    divider: AppColors.grey700,
    shimmer: AppColors.grey800,
    shadow: Color(0x3FFFFFFF),
    primaryGradient: LinearGradient(
      colors: [AppColors.darkPrimary, AppColors.darkPrimaryVariant],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    secondaryGradient: LinearGradient(
      colors: [AppColors.darkSecondary, AppColors.darkSecondaryVariant],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  @override
  CustomColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? cardBackground,
    Color? divider,
    Color? shimmer,
    Color? shadow,
    Gradient? primaryGradient,
    Gradient? secondaryGradient,
  }) {
    return CustomColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      cardBackground: cardBackground ?? this.cardBackground,
      divider: divider ?? this.divider,
      shimmer: shimmer ?? this.shimmer,
      shadow: shadow ?? this.shadow,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      secondaryGradient: secondaryGradient ?? this.secondaryGradient,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      success: Color.lerp(success, other.success, t),
      warning: Color.lerp(warning, other.warning, t),
      info: Color.lerp(info, other.info, t),
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t),
      divider: Color.lerp(divider, other.divider, t),
      shimmer: Color.lerp(shimmer, other.shimmer, t),
      shadow: Color.lerp(shadow, other.shadow, t),
      primaryGradient: Gradient.lerp(primaryGradient, other.primaryGradient, t),
      secondaryGradient: Gradient.lerp(
        secondaryGradient,
        other.secondaryGradient,
        t,
      ),
    );
  }
}

/// Extension for easy access to custom colors
extension CustomColorsExtension on BuildContext {
  CustomColors get customColors {
    return Theme.of(this).extension<CustomColors>() ?? CustomColors.light;
  }
}
