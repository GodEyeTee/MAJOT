/// User role enumeration with comprehensive role metadata
enum UserRole { admin, editor, user, guest }

/// Extension to add properties to UserRole
extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.editor:
        return 'editor';
      case UserRole.user:
        return 'user';
      case UserRole.guest:
        return 'guest';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.editor:
        return 'Editor';
      case UserRole.user:
        return 'User';
      case UserRole.guest:
        return 'Guest';
    }
  }

  int get priority {
    switch (this) {
      case UserRole.admin:
        return 100;
      case UserRole.editor:
        return 75;
      case UserRole.user:
        return 50;
      case UserRole.guest:
        return 25;
    }
  }

  bool hasHigherOrEqualPriorityThan(UserRole other) {
    return priority >= other.priority;
  }
}

/// Permission level enumeration
enum PermissionLevel { basic, standard, advanced, critical }

/// Enhanced permission class with comprehensive metadata
class Permission {
  final String id;
  final String name;
  final String description;
  final String category;
  final PermissionLevel level;
  final List<String> dependencies;
  final bool isSystemPermission;

  static var camera;

  static var storage;

  const Permission({
    required this.id,
    required this.name,
    required this.description,
    this.category = 'general',
    this.level = PermissionLevel.basic,
    this.dependencies = const [],
    this.isSystemPermission = false,
  });
}

/// Role configuration class
class RoleConfiguration {
  final UserRole role;
  final List<Permission> permissions;
  final Map<String, dynamic> metadata;
  final bool isTemporary;
  final DateTime? expiryDate;

  const RoleConfiguration({
    required this.role,
    required this.permissions,
    this.metadata = const {},
    this.isTemporary = false,
    this.expiryDate,
  });
}

class RoleManager {
  static final RoleManager _instance = RoleManager._internal();

  factory RoleManager() {
    return _instance;
  }

  RoleManager._internal();

  final Map<UserRole, List<Permission>> _rolePermissions = {
    UserRole.admin: [
      const Permission(
        id: 'manage_users',
        name: 'Manage Users',
        description: 'Can manage all users and assign roles',
        category: 'user_management',
        level: PermissionLevel.critical,
        isSystemPermission: true,
      ),
      const Permission(
        id: 'manage_roles',
        name: 'Manage Roles',
        description: 'Can manage user roles and permissions',
        category: 'user_management',
        level: PermissionLevel.critical,
        isSystemPermission: true,
      ),
      const Permission(
        id: 'view_analytics',
        name: 'View Analytics',
        description: 'Can view detailed analytics and reports',
        category: 'analytics',
        level: PermissionLevel.advanced,
      ),
      const Permission(
        id: 'manage_hotels',
        name: 'Manage Hotels',
        description: 'Can add, edit, and delete hotels',
        category: 'hotel_management',
        level: PermissionLevel.advanced,
      ),
      const Permission(
        id: 'manage_products',
        name: 'Manage Products',
        description: 'Can add, edit, and delete products',
        category: 'product_management',
        level: PermissionLevel.advanced,
      ),
      const Permission(
        id: 'book_hotels',
        name: 'Book Hotels',
        description: 'Can book hotels for customers',
        category: 'hotel_booking',
        level: PermissionLevel.standard,
      ),
      const Permission(
        id: 'purchase_products',
        name: 'Purchase Products',
        description: 'Can purchase products',
        category: 'shopping',
        level: PermissionLevel.standard,
      ),
      const Permission(
        id: 'use_scanner',
        name: 'Use OCR Scanner',
        description: 'Can use OCR scanning functionality',
        category: 'tools',
        level: PermissionLevel.basic,
      ),
    ],
    UserRole.editor: [
      const Permission(
        id: 'view_analytics',
        name: 'View Analytics',
        description: 'Can view analytics and generate reports',
        category: 'analytics',
        level: PermissionLevel.advanced,
      ),
      const Permission(
        id: 'manage_hotels',
        name: 'Manage Hotels',
        description: 'Can add, edit hotels and manage bookings',
        category: 'hotel_management',
        level: PermissionLevel.advanced,
      ),
      const Permission(
        id: 'manage_products',
        name: 'Manage Products',
        description: 'Can add, edit products and manage inventory',
        category: 'product_management',
        level: PermissionLevel.advanced,
      ),
      const Permission(
        id: 'book_hotels',
        name: 'Book Hotels',
        description: 'Can book hotels for customers',
        category: 'hotel_booking',
        level: PermissionLevel.standard,
      ),
      const Permission(
        id: 'purchase_products',
        name: 'Purchase Products',
        description: 'Can purchase products',
        category: 'shopping',
        level: PermissionLevel.standard,
      ),
      const Permission(
        id: 'use_scanner',
        name: 'Use OCR Scanner',
        description: 'Can use OCR scanning functionality',
        category: 'tools',
        level: PermissionLevel.basic,
      ),
    ],
    UserRole.user: [
      const Permission(
        id: 'use_scanner',
        name: 'Use OCR Scanner',
        description: 'Can use OCR scanner for personal use',
        category: 'tools',
        level: PermissionLevel.basic,
      ),
    ],
    UserRole.guest: [],
  };

  bool hasPermission(UserRole role, String permissionId) {
    final permissions = _rolePermissions[role] ?? [];
    return permissions.any((permission) => permission.id == permissionId);
  }

  List<Permission> getPermissionsForRole(UserRole role) {
    return _rolePermissions[role] ?? [];
  }

  List<Permission> getAllPermissions() {
    final allPermissions = <Permission>{};
    for (final permissions in _rolePermissions.values) {
      allPermissions.addAll(permissions);
    }
    return allPermissions.toList();
  }

  List<String> getAllCategories() {
    final categories = <String>{};
    for (final permissions in _rolePermissions.values) {
      categories.addAll(permissions.map((p) => p.category));
    }
    return categories.toList()..sort();
  }

  List<Permission> getPermissionsByCategory(String category) {
    final permissions = <Permission>{};
    for (final rolePermissions in _rolePermissions.values) {
      permissions.addAll(rolePermissions.where((p) => p.category == category));
    }
    return permissions.toList();
  }

  String getSecurityLevel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'high';
      case UserRole.editor:
        return 'medium';
      case UserRole.user:
        return 'standard';
      case UserRole.guest:
        return 'low';
    }
  }

  Duration getSessionTimeout(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Duration(hours: 2);
      case UserRole.editor:
        return const Duration(hours: 4);
      case UserRole.user:
        return const Duration(hours: 8);
      case UserRole.guest:
        return const Duration(hours: 1);
    }
  }

  RoleConfiguration? getRoleConfiguration(UserRole role) {
    final permissions = getPermissionsForRole(role);
    return RoleConfiguration(
      role: role,
      permissions: permissions,
      metadata: {
        'description': _getRoleDescription(role),
        'requires_mfa': role == UserRole.admin,
        'max_sessions': _getMaxSessions(role),
      },
    );
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Full system access with administrative privileges';
      case UserRole.editor:
        return 'Content management and moderate administrative access';
      case UserRole.user:
        return 'Standard user access with limited permissions';
      case UserRole.guest:
        return 'Limited guest access for viewing only';
    }
  }

  int _getMaxSessions(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 1;
      case UserRole.editor:
        return 3;
      case UserRole.user:
        return 5;
      case UserRole.guest:
        return 10;
    }
  }
}
