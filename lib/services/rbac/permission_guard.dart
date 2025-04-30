// lib/services/rbac/permission_guard.dart
import 'package:flutter/material.dart';
import 'role_manager.dart';

class PermissionGuard extends StatelessWidget {
  final UserRole userRole;
  final String permissionId;
  final Widget child;
  final Widget? fallback;

  const PermissionGuard({
    super.key,
    required this.userRole,
    required this.permissionId,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final roleManager = RoleManager();
    final hasPermission = roleManager.hasPermission(userRole, permissionId);

    if (hasPermission) {
      return child;
    } else {
      return fallback ?? const SizedBox.shrink();
    }
  }
}
