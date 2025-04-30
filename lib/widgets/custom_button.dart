import 'package:flutter/material.dart';

enum ButtonType { primary, secondary, outlined, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsets padding;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null && !isLoading) ...[
          Icon(icon),
          const SizedBox(width: 8),
        ],
        if (isLoading)
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == ButtonType.outlined ? theme.primaryColor : Colors.white,
              ),
            ),
          )
        else
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );

    switch (type) {
      case ButtonType.primary:
        return SizedBox(
          width: width,
          height: height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              padding: padding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            child: buttonChild,
          ),
        );

      case ButtonType.secondary:
        return SizedBox(
          width: width,
          height: height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              padding: padding,
              backgroundColor: theme.colorScheme.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            child: buttonChild,
          ),
        );

      case ButtonType.outlined:
        return SizedBox(
          width: width,
          height: height,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              padding: padding,
              side: BorderSide(color: theme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            child: buttonChild,
          ),
        );

      case ButtonType.text:
        return SizedBox(
          width: width,
          height: height,
          child: TextButton(
            onPressed: isLoading ? null : onPressed,
            style: TextButton.styleFrom(
              padding: padding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            child: buttonChild,
          ),
        );
    }
  }
}
