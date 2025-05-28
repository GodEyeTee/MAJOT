// lib/services/rbac/permission_guard.dart
import 'package:flutter/material.dart';
import 'rbac_service.dart';

class PermissionGuard extends StatelessWidget {
  final String permissionId;
  final Widget child;
  final Widget? fallback;

  const PermissionGuard({
    super.key,
    required this.permissionId,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final rbacService = RBACService();
    final hasPermission = rbacService.hasPermission(permissionId);

    if (hasPermission) {
      return child;
    } else {
      return fallback ?? const SizedBox.shrink();
    }
  }
}

// สำหรับการใช้งานแบบ multiple permissions
class MultiPermissionGuard extends StatelessWidget {
  final List<String> requiredPermissions;
  final bool
  requireAll; // true = ต้องมีทุก permission, false = มี permission ใดก็ได้
  final Widget child;
  final Widget? fallback;

  const MultiPermissionGuard({
    super.key,
    required this.requiredPermissions,
    required this.child,
    this.requireAll = false,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final rbacService = RBACService();

    final hasPermission =
        requireAll
            ? rbacService.hasAllPermissions(requiredPermissions)
            : rbacService.hasAnyPermission(requiredPermissions);

    if (hasPermission) {
      return child;
    } else {
      return fallback ?? const SizedBox.shrink();
    }
  }
}

// Widget สำหรับแสดงข้อมูล permission ปัจจุบัน (สำหรับ debug)
class PermissionDebugInfo extends StatelessWidget {
  const PermissionDebugInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final rbacService = RBACService();
    final currentUser = rbacService.currentUser;
    final permissions = rbacService.getCurrentUserPermissions();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current User: ${currentUser?.email ?? 'Not logged in'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Role: ${currentUser?.role.toString().split('.').last ?? 'None'}',
            ),
            const SizedBox(height: 8),
            const Text(
              'Permissions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...permissions.map((p) => Text('• ${p.name}')),
          ],
        ),
      ),
    );
  }
}
