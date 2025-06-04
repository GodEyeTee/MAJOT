import 'package:flutter/material.dart';

/// Typography configuration
class AppTypography {
  // Font families
  static const String primaryFontFamily = 'Roboto';
  static const String secondaryFontFamily = 'Roboto';

  // Base text theme
  static TextTheme get baseTextTheme => const TextTheme(
    // Display styles
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.22,
    ),

    // Headline styles
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.33,
    ),

    // Title styles
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.50,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),

    // Body styles
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.50,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.33,
    ),

    // Label styles
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.45,
    ),
  );

  // Light theme text theme
  static TextTheme lightTextTheme = baseTextTheme.apply(
    bodyColor: Colors.black87,
    displayColor: Colors.black87,
    decorationColor: Colors.black54,
  );

  // Dark theme text theme
  static TextTheme darkTextTheme = baseTextTheme.apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
    decorationColor: Colors.white70,
  );
}

/// Custom typography extension
@immutable
class CustomTypography extends ThemeExtension<CustomTypography> {
  final TextStyle? h1;
  final TextStyle? h2;
  final TextStyle? h3;
  final TextStyle? h4;
  final TextStyle? h5;
  final TextStyle? h6;
  final TextStyle? subtitle1;
  final TextStyle? subtitle2;
  final TextStyle? body1;
  final TextStyle? body2;
  final TextStyle? button;
  final TextStyle? caption;
  final TextStyle? overline;
  final TextStyle? code;
  final TextStyle? quote;

  const CustomTypography({
    this.h1,
    this.h2,
    this.h3,
    this.h4,
    this.h5,
    this.h6,
    this.subtitle1,
    this.subtitle2,
    this.body1,
    this.body2,
    this.button,
    this.caption,
    this.overline,
    this.code,
    this.quote,
  });

  static const light = CustomTypography(
    h1: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
      height: 1.25,
    ),
    h2: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
      height: 1.3,
    ),
    h3: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
      height: 1.35,
    ),
    h4: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
      height: 1.4,
    ),
    h5: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: Colors.black87,
      height: 1.45,
    ),
    h6: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Colors.black87,
      height: 1.5,
    ),
    subtitle1: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Colors.black87,
      height: 1.5,
    ),
    subtitle2: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.black87,
      height: 1.45,
    ),
    body1: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Colors.black87,
      height: 1.5,
    ),
    body2: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: Colors.black87,
      height: 1.45,
    ),
    button: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.25,
      color: Colors.black87,
    ),
    caption: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: Colors.black54,
      height: 1.4,
    ),
    overline: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.5,
      color: Colors.black54,
    ),
    code: TextStyle(
      fontSize: 14,
      fontFamily: 'monospace',
      color: Colors.black87,
      backgroundColor: Colors.grey,
    ),
    quote: TextStyle(
      fontSize: 16,
      fontStyle: FontStyle.italic,
      color: Colors.black54,
      height: 1.6,
    ),
  );

  static const dark = CustomTypography(
    h1: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      height: 1.25,
    ),
    h2: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      height: 1.3,
    ),
    h3: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.35,
    ),
    h4: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.4,
    ),
    h5: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: Colors.white,
      height: 1.45,
    ),
    h6: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Colors.white,
      height: 1.5,
    ),
    subtitle1: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Colors.white,
      height: 1.5,
    ),
    subtitle2: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.white,
      height: 1.45,
    ),
    body1: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Colors.white,
      height: 1.5,
    ),
    body2: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: Colors.white,
      height: 1.45,
    ),
    button: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.25,
      color: Colors.white,
    ),
    caption: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: Colors.white70,
      height: 1.4,
    ),
    overline: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.5,
      color: Colors.white70,
    ),
    code: TextStyle(
      fontSize: 14,
      fontFamily: 'monospace',
      color: Colors.white,
      backgroundColor: Color(0xFF2A2A2A),
    ),
    quote: TextStyle(
      fontSize: 16,
      fontStyle: FontStyle.italic,
      color: Colors.white70,
      height: 1.6,
    ),
  );

  @override
  CustomTypography copyWith({
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? h4,
    TextStyle? h5,
    TextStyle? h6,
    TextStyle? subtitle1,
    TextStyle? subtitle2,
    TextStyle? body1,
    TextStyle? body2,
    TextStyle? button,
    TextStyle? caption,
    TextStyle? overline,
    TextStyle? code,
    TextStyle? quote,
  }) {
    return CustomTypography(
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      h4: h4 ?? this.h4,
      h5: h5 ?? this.h5,
      h6: h6 ?? this.h6,
      subtitle1: subtitle1 ?? this.subtitle1,
      subtitle2: subtitle2 ?? this.subtitle2,
      body1: body1 ?? this.body1,
      body2: body2 ?? this.body2,
      button: button ?? this.button,
      caption: caption ?? this.caption,
      overline: overline ?? this.overline,
      code: code ?? this.code,
      quote: quote ?? this.quote,
    );
  }

  @override
  CustomTypography lerp(ThemeExtension<CustomTypography>? other, double t) {
    if (other is! CustomTypography) {
      return this;
    }
    return CustomTypography(
      h1: TextStyle.lerp(h1, other.h1, t),
      h2: TextStyle.lerp(h2, other.h2, t),
      h3: TextStyle.lerp(h3, other.h3, t),
      h4: TextStyle.lerp(h4, other.h4, t),
      h5: TextStyle.lerp(h5, other.h5, t),
      h6: TextStyle.lerp(h6, other.h6, t),
      subtitle1: TextStyle.lerp(subtitle1, other.subtitle1, t),
      subtitle2: TextStyle.lerp(subtitle2, other.subtitle2, t),
      body1: TextStyle.lerp(body1, other.body1, t),
      body2: TextStyle.lerp(body2, other.body2, t),
      button: TextStyle.lerp(button, other.button, t),
      caption: TextStyle.lerp(caption, other.caption, t),
      overline: TextStyle.lerp(overline, other.overline, t),
      code: TextStyle.lerp(code, other.code, t),
      quote: TextStyle.lerp(quote, other.quote, t),
    );
  }
}

/// Extension for easy access to custom typography
extension CustomTypographyExtension on BuildContext {
  CustomTypography get typography {
    return Theme.of(this).extension<CustomTypography>() ??
        CustomTypography.light;
  }
}
