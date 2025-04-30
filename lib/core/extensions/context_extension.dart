import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {
  // Media query extensions
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get size => mediaQuery.size;
  double get height => size.height;
  double get width => size.width;

  // Theme extensions
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  // Screen metrics
  bool get isSmallScreen => width < 600;
  bool get isMediumScreen => width >= 600 && width < 1024;
  bool get isLargeScreen => width >= 1024;

  // Padding
  EdgeInsets get defaultPadding => const EdgeInsets.all(16.0);
  EdgeInsets get horizontalPadding =>
      const EdgeInsets.symmetric(horizontal: 16.0);
  EdgeInsets get verticalPadding => const EdgeInsets.symmetric(vertical: 16.0);

  // Navigation
  void pop<T>([T? result]) => Navigator.of(this).pop<T>(result);
  Future<T?> push<T>(Widget page) =>
      Navigator.of(this).push<T>(MaterialPageRoute(builder: (_) => page));
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) =>
      Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  Future<T?> pushReplacementNamed<T, TO>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) => Navigator.of(this).pushReplacementNamed<T, TO>(
    routeName,
    result: result,
    arguments: arguments,
  );
  Future<T?> pushNamedAndRemoveUntil<T>(
    String newRouteName,
    RoutePredicate predicate, {
    Object? arguments,
  }) => Navigator.of(
    this,
  ).pushNamedAndRemoveUntil<T>(newRouteName, predicate, arguments: arguments);

  // Dialogs
  Future<void> showLoadingDialog() => showDialog(
    context: this,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  Future<bool?> showConfirmationDialog({
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
  }) async {
    return showDialog<bool>(
      context: this,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelText ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmText ?? 'Confirm'),
              ),
            ],
          ),
    );
  }

  void showSnackBar(
    String message, {
    Color? backgroundColor,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 2),
      ),
    );
  }
}
