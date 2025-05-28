import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'rbac_service.dart';
import 'role_manager.dart';
import '../../features/auth/domain/entities/user.dart';

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

    // Skip permission check if empty permission ID
    if (permissionId.isEmpty) {
      return child;
    }

    final hasPermission = rbacService.hasPermission(permissionId);

    if (hasPermission) {
      return _wrapWithDebugInfo(context, child, true);
    } else {
      // Call permission denied callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPermissionDenied?.call();
      });

      return _wrapWithDebugInfo(
        context,
        fallback ?? _buildDefaultFallback(context),
        false,
      );
    }
  }

  /// Wrap widget with debug information if enabled
  Widget _wrapWithDebugInfo(
    BuildContext context,
    Widget widget,
    bool hasPermission,
  ) {
    if (!showDebugInfo || kReleaseMode) {
      return widget;
    }

    return Stack(
      children: [
        widget,
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: hasPermission ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              hasPermission ? '✓' : '✗',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build default fallback widget
  Widget _buildDefaultFallback(BuildContext context) {
    return const SizedBox.shrink();
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

    // No permissions required - allow access
    if (requiredPermissions.isEmpty) {
      return _wrapWithDebugInfo(context, child, true);
    }

    final hasPermission =
        requireAll
            ? rbacService.hasAllPermissions(requiredPermissions)
            : rbacService.hasAnyPermission(requiredPermissions);

    if (hasPermission) {
      return _wrapWithDebugInfo(context, child, true);
    } else {
      // Call permission denied callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPermissionDenied?.call();
      });

      return _wrapWithDebugInfo(
        context,
        fallback ?? _buildDefaultFallback(context),
        false,
      );
    }
  }

  /// Wrap widget with debug information if enabled
  Widget _wrapWithDebugInfo(
    BuildContext context,
    Widget widget,
    bool hasPermission,
  ) {
    if (!showDebugInfo || kReleaseMode) {
      return widget;
    }

    return Stack(
      children: [
        widget,
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: hasPermission ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasPermission ? '✓' : '✗',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  requireAll ? 'ALL' : 'ANY',
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build default fallback widget
  Widget _buildDefaultFallback(BuildContext context) {
    return const SizedBox.shrink();
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

    // No user - deny access
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onAccessDenied?.call();
      });
      return _wrapWithDebugInfo(
        context,
        fallback ?? _buildDefaultFallback(context),
        false,
      );
    }

    // Check if user's role is in allowed roles
    final hasAccess = allowedRoles.contains(currentUser.role);

    if (hasAccess) {
      return _wrapWithDebugInfo(context, child, true);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onAccessDenied?.call();
      });
      return _wrapWithDebugInfo(
        context,
        fallback ?? _buildDefaultFallback(context),
        false,
      );
    }
  }

  /// Wrap widget with debug information if enabled
  Widget _wrapWithDebugInfo(
    BuildContext context,
    Widget widget,
    bool hasAccess,
  ) {
    if (!showDebugInfo || kReleaseMode) {
      return widget;
    }

    final rbacService = RBACService();
    final currentRole = rbacService.currentUser?.role;

    return Stack(
      children: [
        widget,
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: hasAccess ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasAccess ? '✓' : '✗',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentRole?.name.toUpperCase() ?? 'NONE',
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build default fallback widget
  Widget _buildDefaultFallback(BuildContext context) {
    return const SizedBox.shrink();
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
      return _wrapWithDebugInfo(context, child, true);
    } else {
      return _wrapWithDebugInfo(
        context,
        fallback ?? const SizedBox.shrink(),
        false,
      );
    }
  }

  /// Wrap widget with debug information if enabled
  Widget _wrapWithDebugInfo(
    BuildContext context,
    Widget widget,
    bool conditionMet,
  ) {
    if (!showDebugInfo || kReleaseMode) {
      return widget;
    }

    return Stack(
      children: [
        widget,
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: conditionMet ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  conditionMet ? '✓' : '✗',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (debugLabel != null)
                  Text(
                    debugLabel!,
                    style: const TextStyle(color: Colors.white, fontSize: 8),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget to display current user's permission information for debugging
class PermissionDebugInfo extends StatelessWidget {
  final bool showFullDetails;

  const PermissionDebugInfo({super.key, this.showFullDetails = false});

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      return const SizedBox.shrink();
    }

    final rbacService = RBACService();
    final currentUser = rbacService.currentUser;
    final permissions = rbacService.getCurrentUserPermissions();
    final roleManager = RoleManager();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Permission Debug Info',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 12),

            // User Information
            _buildInfoSection('User Information', [
              'Email: ${currentUser?.email ?? 'Not logged in'}',
              'Role: ${currentUser?.role.toString().split('.').last ?? 'None'}',
              'Role Priority: ${currentUser?.role.priority ?? 'N/A'}',
              'Role Display Name: ${currentUser?.role.displayName ?? 'N/A'}',
            ]),

            const SizedBox(height: 12),

            // Permissions
            _buildInfoSection(
              'Permissions (${permissions.length})',
              permissions.map((p) => '• ${p.name} (${p.id})').toList(),
            ),

            if (showFullDetails) ...[
              const SizedBox(height: 12),

              // Security Statistics
              _buildSecurityStats(rbacService),

              const SizedBox(height: 12),

              // Role Configuration
              if (currentUser != null)
                _buildRoleConfiguration(roleManager, currentUser.role),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Text(item, style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityStats(RBACService rbacService) {
    final stats = rbacService.getSecurityStatistics();
    final accessStats = stats['access_statistics'] as Map<String, dynamic>?;

    return _buildInfoSection('Security Statistics', [
      'Access Attempts: ${accessStats?['total_attempts'] ?? 0}',
      'Denied Attempts: ${accessStats?['denied_attempts'] ?? 0}',
      'Success Rate: ${accessStats?['success_rate'] ?? '0.0%'}',
      'Health Score: ${rbacService.performSecurityHealthCheck()['health_score'] ?? 0}/100',
    ]);
  }

  Widget _buildRoleConfiguration(RoleManager roleManager, UserRole role) {
    final config = roleManager.getRoleConfiguration(role);
    if (config == null) return const SizedBox.shrink();

    final metadata = config.metadata;

    return _buildInfoSection('Role Configuration', [
      'Description: ${metadata['description'] ?? 'No description'}',
      'Security Level: ${roleManager.getSecurityLevel(role)}',
      'Session Timeout: ${roleManager.getSessionTimeout(role).inMinutes} minutes',
      'MFA Required: ${metadata['requires_mfa'] ?? false}',
      'Temporary Role: ${config.isTemporary}',
      'Valid Until: ${config.expiryDate?.toLocal().toString() ?? 'Permanent'}',
    ]);
  }
}

/// Widget to display all available permissions (for admin users)
class PermissionListView extends StatelessWidget {
  final bool groupByCategory;
  final String? filterCategory;
  final bool showDescriptions;

  const PermissionListView({
    super.key,
    this.groupByCategory = true,
    this.filterCategory,
    this.showDescriptions = true,
  });

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      return const Center(
        child: Text('Permission list not available in production mode'),
      );
    }

    final roleManager = RoleManager();
    final rbacService = RBACService();

    // Check if user has permission to view this
    if (!rbacService.hasPermission('manage_roles')) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Access denied - Requires role management permission'),
          ],
        ),
      );
    }

    final allPermissions = roleManager.getAllPermissions();
    final categories = roleManager.getAllCategories();

    if (groupByCategory) {
      return _buildCategorizedView(roleManager, categories, rbacService);
    } else {
      return _buildFlatView(allPermissions, rbacService);
    }
  }

  Widget _buildCategorizedView(
    RoleManager roleManager,
    List<String> categories,
    RBACService rbacService,
  ) {
    final filteredCategories =
        filterCategory != null
            ? categories.where((cat) => cat == filterCategory).toList()
            : categories;

    return ListView.builder(
      itemCount: filteredCategories.length,
      itemBuilder: (context, index) {
        final category = filteredCategories[index];
        final permissions = roleManager.getPermissionsByCategory(category);

        return ExpansionTile(
          title: Text(
            _formatCategoryName(category),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${permissions.length} permissions'),
          children:
              permissions
                  .map(
                    (permission) =>
                        _buildPermissionTile(permission, rbacService),
                  )
                  .toList(),
        );
      },
    );
  }

  Widget _buildFlatView(List<Permission> permissions, RBACService rbacService) {
    final filteredPermissions =
        filterCategory != null
            ? permissions.where((p) => p.category == filterCategory).toList()
            : permissions;

    return ListView.builder(
      itemCount: filteredPermissions.length,
      itemBuilder: (context, index) {
        return _buildPermissionTile(filteredPermissions[index], rbacService);
      },
    );
  }

  Widget _buildPermissionTile(Permission permission, RBACService rbacService) {
    final hasPermission = rbacService.hasPermission(permission.id);

    return ListTile(
      leading: Icon(
        hasPermission ? Icons.check_circle : Icons.cancel,
        color: hasPermission ? Colors.green : Colors.red,
      ),
      title: Text(permission.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${permission.id}'),
          if (showDescriptions) Text(permission.description),
          if (permission.dependencies.isNotEmpty)
            Text('Depends on: ${permission.dependencies.join(', ')}'),
        ],
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            permission.level.name.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: _getLevelColor(permission.level),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (permission.isSystemPermission)
            const Icon(Icons.security, size: 16, color: Colors.orange),
        ],
      ),
    );
  }

  String _formatCategoryName(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color _getLevelColor(PermissionLevel level) {
    switch (level) {
      case PermissionLevel.basic:
        return Colors.green;
      case PermissionLevel.standard:
        return Colors.blue;
      case PermissionLevel.advanced:
        return Colors.orange;
      case PermissionLevel.critical:
        return Colors.red;
    }
  }
}

/// Helper functions for creating permission-based UI elements

/// Create a button that's only enabled if user has permission
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

/// Create a menu item that's only visible if user has permission
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

/// Create a floating action button that requires permission
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
