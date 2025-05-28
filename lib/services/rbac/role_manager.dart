enum UserRole { admin, editor, user }

class Permission {
  final String id;
  final String name;
  final String description;

  const Permission({
    required this.id,
    required this.name,
    required this.description,
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
      Permission(
        id: 'manage_users',
        name: 'Manage Users',
        description: 'Can manage all users and assign roles',
      ),
      Permission(
        id: 'manage_roles',
        name: 'Manage Roles',
        description: 'Can manage user roles and permissions',
      ),
      Permission(
        id: 'view_analytics',
        name: 'View Analytics',
        description: 'Can view detailed analytics and reports',
      ),
      Permission(
        id: 'manage_hotels',
        name: 'Manage Hotels',
        description: 'Can add, edit, and delete hotels',
      ),
      Permission(
        id: 'manage_products',
        name: 'Manage Products',
        description: 'Can add, edit, and delete products',
      ),
      Permission(
        id: 'book_hotels',
        name: 'Book Hotels',
        description: 'Can book hotels for customers',
      ),
      Permission(
        id: 'purchase_products',
        name: 'Purchase Products',
        description: 'Can purchase products',
      ),
      Permission(
        id: 'use_scanner',
        name: 'Use OCR Scanner',
        description: 'Can use OCR scanning functionality',
      ),
    ],
    UserRole.editor: [
      Permission(
        id: 'view_analytics',
        name: 'View Analytics',
        description: 'Can view analytics and generate reports',
      ),
      Permission(
        id: 'manage_hotels',
        name: 'Manage Hotels',
        description: 'Can add, edit hotels and manage bookings',
      ),
      Permission(
        id: 'manage_products',
        name: 'Manage Products',
        description: 'Can add, edit products and manage inventory',
      ),
      Permission(
        id: 'book_hotels',
        name: 'Book Hotels',
        description: 'Can book hotels for customers',
      ),
      Permission(
        id: 'purchase_products',
        name: 'Purchase Products',
        description: 'Can purchase products',
      ),
      Permission(
        id: 'use_scanner',
        name: 'Use OCR Scanner',
        description: 'Can use OCR scanning functionality',
      ),
    ],
    UserRole.user: [
      Permission(
        id: 'book_hotels',
        name: 'Book Hotels',
        description: 'Can search and book hotels',
      ),
      Permission(
        id: 'purchase_products',
        name: 'Purchase Products',
        description: 'Can browse and purchase products',
      ),
      Permission(
        id: 'use_scanner',
        name: 'Use OCR Scanner',
        description: 'Can use OCR scanner for personal use',
      ),
    ],
  };

  bool hasPermission(UserRole role, String permissionId) {
    final permissions = _rolePermissions[role] ?? [];
    return permissions.any((permission) => permission.id == permissionId);
  }

  List<Permission> getPermissionsForRole(UserRole role) {
    return _rolePermissions[role] ?? [];
  }
}
