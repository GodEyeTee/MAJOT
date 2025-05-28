import 'role_manager.dart';
import '../../features/auth/domain/entities/user.dart';

class RBACService {
  static final RBACService _instance = RBACService._internal();
  factory RBACService() => _instance;
  RBACService._internal();

  final RoleManager _roleManager = RoleManager();
  User? _currentUser;

  void setCurrentUser(User? user) {
    _currentUser = user;
    print('🔄 RBAC: Current user set to: ${user?.email} (${user?.role})');
  }

  User? get currentUser => _currentUser;

  bool hasPermission(String permissionId) {
    if (_currentUser == null) {
      print('⚠️ RBAC: No current user, permission denied for: $permissionId');
      return false;
    }

    final hasAccess = _roleManager.hasPermission(
      _currentUser!.role,
      permissionId,
    );

    if (hasAccess) {
      print(
        '✅ RBAC: Permission granted for ${_currentUser!.email}: $permissionId',
      );
    } else {
      print(
        '❌ RBAC: Permission denied for ${_currentUser!.email}: $permissionId',
      );
    }

    return hasAccess;
  }

  bool hasAnyPermission(List<String> permissions) {
    if (_currentUser == null) {
      print(
        '⚠️ RBAC: No current user, access denied for permissions: $permissions',
      );
      return false;
    }

    final hasAccess = permissions.any(
      (permission) => hasPermission(permission),
    );
    print(
      '🔍 RBAC: hasAnyPermission check for ${permissions.join(', ')}: $hasAccess',
    );
    return hasAccess;
  }

  bool hasAllPermissions(List<String> permissions) {
    if (_currentUser == null) {
      print(
        '⚠️ RBAC: No current user, access denied for all permissions: $permissions',
      );
      return false;
    }

    final hasAccess = permissions.every(
      (permission) => hasPermission(permission),
    );
    print(
      '🔍 RBAC: hasAllPermissions check for ${permissions.join(', ')}: $hasAccess',
    );
    return hasAccess;
  }

  List<Permission> getCurrentUserPermissions() {
    if (_currentUser == null) {
      print('⚠️ RBAC: No current user, returning empty permissions');
      return [];
    }

    final permissions = _roleManager.getPermissionsForRole(_currentUser!.role);
    print(
      '📋 RBAC: Current user permissions: ${permissions.map((p) => p.id).join(', ')}',
    );
    return permissions;
  }

  // Helper method สำหรับ debug
  void printCurrentUserInfo() {
    if (_currentUser != null) {
      print('👤 Current User Info:');
      print('   Email: ${_currentUser!.email}');
      print('   Role: ${_currentUser!.role}');
      print(
        '   Permissions: ${getCurrentUserPermissions().map((p) => p.id).join(', ')}',
      );
    } else {
      print('👤 No current user logged in');
    }
  }

  // Helper method สำหรับเช็คว่า user เป็น admin หรือไม่
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  // Helper method สำหรับเช็คว่า user เป็น editor หรือไม่
  bool get isEditor => _currentUser?.role == UserRole.editor;

  // Helper method สำหรับเช็คว่า user เป็น regular user หรือไม่
  bool get isUser => _currentUser?.role == UserRole.user;
}
