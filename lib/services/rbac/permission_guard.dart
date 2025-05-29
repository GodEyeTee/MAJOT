import 'package:flutter/material.dart';
import 'rbac_service.dart';
import 'role_manager.dart';

/// Single permission guard widget
class PermissionGuard extends StatelessWidget {
  final String permissionId;
  final Widget child;
  final Widget? fallback;
  final bool showDebugInfo;
  final VoidCallback? onPermissionDenied;

  const PermissionGuard({
    super.key,
    required this.permissionId,
    required this.child,
    this.fallback,
    this.showDebugInfo = false,
    this.onPermissionDenied,
  });

  @override
  Widget build(BuildContext context) {
    final rbacService = RBACService();

    if (permissionId.isEmpty) {
      return child;
    }

    final hasPermission = rbacService.hasPermission(permissionId);

    if (hasPermission) {
      return child;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPermissionDenied?.call();
      });
      return fallback ?? const SizedBox.shrink();
    }
  }
}

/// Multiple permissions guard widget
class MultiPermissionGuard extends StatelessWidget {
  final List<String> requiredPermissions;
  final bool requireAll;
  final Widget child;
  final Widget? fallback;
  final bool showDebugInfo;
  final VoidCallback? onPermissionDenied;

  const MultiPermissionGuard({
    super.key,
    required this.requiredPermissions,
    required this.child,
    this.requireAll = false,
    this.fallback,
    this.showDebugInfo = false,
    this.onPermissionDenied,
  });

  @override
  Widget build(BuildContext context) {
    final rbacService = RBACService();

    if (requiredPermissions.isEmpty) {
      return child;
    }

    final hasPermission =
        requireAll
            ? rbacService.hasAllPermissions(requiredPermissions)
            : rbacService.hasAnyPermission(requiredPermissions);

    if (hasPermission) {
      return child;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPermissionDenied?.call();
      });
      return fallback ?? const SizedBox.shrink();
    }
  }
}

/// Role-based guard widget
class RoleGuard extends StatelessWidget {
  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;
  final bool showDebugInfo;
  final VoidCallback? onAccessDenied;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
    this.showDebugInfo = false,
    this.onAccessDenied,
  });

  @override
  Widget build(BuildContext context) {
    final rbacService = RBACService();
    final currentUser = rbacService.currentUser;

    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onAccessDenied?.call();
      });
      return fallback ?? const SizedBox.shrink();
    }

    final hasAccess = allowedRoles.contains(currentUser.role);

    if (hasAccess) {
      return child;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onAccessDenied?.call();
      });
      return fallback ?? const SizedBox.shrink();
    }
  }
}

/// Conditional guard based on custom logic
class ConditionalGuard extends StatelessWidget {
  final bool Function() condition;
  final Widget child;
  final Widget? fallback;
  final String? debugLabel;
  final bool showDebugInfo;

  const ConditionalGuard({
    super.key,
    required this.condition,
    required this.child,
    this.fallback,
    this.debugLabel,
    this.showDebugInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final conditionMet = condition();

    if (conditionMet) {
      return child;
    } else {
      return fallback ?? const SizedBox.shrink();
    }
  }
}

/// Helper functions for creating permission-based UI elements
Widget createPermissionButton({
  required String permissionId,
  required String label,
  required VoidCallback onPressed,
  IconData? icon,
  ButtonStyle? style,
}) {
  return Builder(
    builder: (context) {
      final rbacService = RBACService();
      final hasPermission = rbacService.hasPermission(permissionId);

      if (icon != null) {
        return ElevatedButton.icon(
          onPressed: hasPermission ? onPressed : null,
          icon: Icon(icon),
          label: Text(label),
          style: style,
        );
      } else {
        return ElevatedButton(
          onPressed: hasPermission ? onPressed : null,
          style: style,
          child: Text(label),
        );
      }
    },
  );
}

Widget createPermissionMenuItem({
  required String permissionId,
  required String title,
  required VoidCallback onTap,
  IconData? icon,
  String? subtitle,
}) {
  return PermissionGuard(
    permissionId: permissionId,
    child: ListTile(
      leading: icon != null ? Icon(icon) : null,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: onTap,
    ),
  );
}

Widget createPermissionFAB({
  required String permissionId,
  required VoidCallback onPressed,
  required Widget child,
  String? tooltip,
}) {
  return PermissionGuard(
    permissionId: permissionId,
    child: FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      child: child,
    ),
  );
}
