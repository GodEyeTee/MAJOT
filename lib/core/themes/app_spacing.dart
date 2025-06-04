import 'package:flutter/material.dart';

/// Spacing system based on 8pt grid
class AppSpacing {
  // Base unit
  static const double unit = 8.0;

  // Spacing values
  static const double xxs = unit * 0.5; // 4
  static const double xs = unit; // 8
  static const double sm = unit * 1.5; // 12
  static const double md = unit * 2; // 16
  static const double lg = unit * 3; // 24
  static const double xl = unit * 4; // 32
  static const double xxl = unit * 5; // 40
  static const double xxxl = unit * 6; // 48

  // Padding helpers
  static const EdgeInsets paddingXxs = EdgeInsets.all(xxs);
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingXxl = EdgeInsets.all(xxl);

  // Horizontal padding
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);

  // Common patterns
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(md);

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: lg,
  );

  // Gaps for Row/Column
  static const SizedBox gapXxs = SizedBox(width: xxs, height: xxs);
  static const SizedBox gapXs = SizedBox(width: xs, height: xs);
  static const SizedBox gapSm = SizedBox(width: sm, height: sm);
  static const SizedBox gapMd = SizedBox(width: md, height: md);
  static const SizedBox gapLg = SizedBox(width: lg, height: lg);
  static const SizedBox gapXl = SizedBox(width: xl, height: xl);
  static const SizedBox gapXxl = SizedBox(width: xxl, height: xxl);

  // Horizontal gaps
  static const SizedBox horizontalGapXxs = SizedBox(width: xxs);
  static const SizedBox horizontalGapXs = SizedBox(width: xs);
  static const SizedBox horizontalGapSm = SizedBox(width: sm);
  static const SizedBox horizontalGapMd = SizedBox(width: md);
  static const SizedBox horizontalGapLg = SizedBox(width: lg);
  static const SizedBox horizontalGapXl = SizedBox(width: xl);

  // Vertical gaps
  static const SizedBox verticalGapXxs = SizedBox(height: xxs);
  static const SizedBox verticalGapXs = SizedBox(height: xs);
  static const SizedBox verticalGapSm = SizedBox(height: sm);
  static const SizedBox verticalGapMd = SizedBox(height: md);
  static const SizedBox verticalGapLg = SizedBox(height: lg);
  static const SizedBox verticalGapXl = SizedBox(height: xl);
}

/// Custom spacing extension for theme
@immutable
class CustomSpacing extends ThemeExtension<CustomSpacing> {
  final double? cardSpacing;
  final double? listSpacing;
  final double? sectionSpacing;
  final EdgeInsets? screenPadding;
  final EdgeInsets? cardPadding;
  final EdgeInsets? dialogPadding;
  final double? iconSpacing;
  final double? buttonSpacing;

  const CustomSpacing({
    this.cardSpacing,
    this.listSpacing,
    this.sectionSpacing,
    this.screenPadding,
    this.cardPadding,
    this.dialogPadding,
    this.iconSpacing,
    this.buttonSpacing,
  });

  static const standard = CustomSpacing(
    cardSpacing: AppSpacing.md,
    listSpacing: AppSpacing.xs,
    sectionSpacing: AppSpacing.xl,
    screenPadding: EdgeInsets.all(AppSpacing.md),
    cardPadding: EdgeInsets.all(AppSpacing.md),
    dialogPadding: EdgeInsets.all(AppSpacing.lg),
    iconSpacing: AppSpacing.xs,
    buttonSpacing: AppSpacing.sm,
  );

  static const compact = CustomSpacing(
    cardSpacing: AppSpacing.sm,
    listSpacing: AppSpacing.xxs,
    sectionSpacing: AppSpacing.lg,
    screenPadding: EdgeInsets.all(AppSpacing.sm),
    cardPadding: EdgeInsets.all(AppSpacing.sm),
    dialogPadding: EdgeInsets.all(AppSpacing.md),
    iconSpacing: AppSpacing.xxs,
    buttonSpacing: AppSpacing.xs,
  );

  static const comfortable = CustomSpacing(
    cardSpacing: AppSpacing.lg,
    listSpacing: AppSpacing.sm,
    sectionSpacing: AppSpacing.xxl,
    screenPadding: EdgeInsets.all(AppSpacing.lg),
    cardPadding: EdgeInsets.all(AppSpacing.lg),
    dialogPadding: EdgeInsets.all(AppSpacing.xl),
    iconSpacing: AppSpacing.sm,
    buttonSpacing: AppSpacing.md,
  );

  @override
  CustomSpacing copyWith({
    double? cardSpacing,
    double? listSpacing,
    double? sectionSpacing,
    EdgeInsets? screenPadding,
    EdgeInsets? cardPadding,
    EdgeInsets? dialogPadding,
    double? iconSpacing,
    double? buttonSpacing,
  }) {
    return CustomSpacing(
      cardSpacing: cardSpacing ?? this.cardSpacing,
      listSpacing: listSpacing ?? this.listSpacing,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      screenPadding: screenPadding ?? this.screenPadding,
      cardPadding: cardPadding ?? this.cardPadding,
      dialogPadding: dialogPadding ?? this.dialogPadding,
      iconSpacing: iconSpacing ?? this.iconSpacing,
      buttonSpacing: buttonSpacing ?? this.buttonSpacing,
    );
  }

  @override
  CustomSpacing lerp(ThemeExtension<CustomSpacing>? other, double t) {
    if (other is! CustomSpacing) {
      return this;
    }
    return CustomSpacing(
      cardSpacing: _lerpDouble(cardSpacing, other.cardSpacing, t),
      listSpacing: _lerpDouble(listSpacing, other.listSpacing, t),
      sectionSpacing: _lerpDouble(sectionSpacing, other.sectionSpacing, t),
      screenPadding: EdgeInsets.lerp(screenPadding, other.screenPadding, t),
      cardPadding: EdgeInsets.lerp(cardPadding, other.cardPadding, t),
      dialogPadding: EdgeInsets.lerp(dialogPadding, other.dialogPadding, t),
      iconSpacing: _lerpDouble(iconSpacing, other.iconSpacing, t),
      buttonSpacing: _lerpDouble(buttonSpacing, other.buttonSpacing, t),
    );
  }

  double? _lerpDouble(double? a, double? b, double t) {
    if (a == null || b == null) return null;
    return a + (b - a) * t;
  }
}

/// Extension for easy access to custom spacing
extension CustomSpacingExtension on BuildContext {
  CustomSpacing get spacing {
    return Theme.of(this).extension<CustomSpacing>() ?? CustomSpacing.standard;
  }
}
