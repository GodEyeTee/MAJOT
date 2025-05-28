import 'package:flutter/foundation.dart';
import 'role_manager.dart';
import '../../features/auth/domain/entities/user.dart';

class RBACService {
  static final RBACService _instance = RBACService._internal();
  factory RBACService() => _instance;
  RBACService._internal();

  final RoleManager _roleManager = RoleManager();
  User? _currentUser;

  // Security monitoring
  int _accessAttempts = 0;
  int _deniedAttempts = 0;
  final Map<String, int> _permissionAccessCount = {};

  void setCurrentUser(User? user) {
    _currentUser = user;
    if (!kReleaseMode) {
      print('🔄 RBAC: Current user set to: ${user?.email} (${user?.role})');
    }
  }

  User? get currentUser => _currentUser;

  bool hasPermission(String permissionId) {
    _accessAttempts++;
    _permissionAccessCount[permissionId] =
        (_permissionAccessCount[permissionId] ?? 0) + 1;

    if (_currentUser == null) {
      _deniedAttempts++;
      if (!kReleaseMode) {
        print('⚠️ RBAC: No current user, permission denied for: $permissionId');
      }
      return false;
    }

    final hasAccess = _roleManager.hasPermission(
      _currentUser!.role,
      permissionId,
    );

    if (hasAccess) {
      if (!kReleaseMode) {
        print(
          '✅ RBAC: Permission granted for ${_currentUser!.email}: $permissionId',
        );
      }
    } else {
      _deniedAttempts++;
      if (!kReleaseMode) {
        print(
          '❌ RBAC: Permission denied for ${_currentUser!.email}: $permissionId',
        );
      }
    }

    return hasAccess;
  }

  bool hasAnyPermission(List<String> permissions) {
    if (_currentUser == null) {
      if (!kReleaseMode) {
        print(
          '⚠️ RBAC: No current user, access denied for permissions: $permissions',
        );
      }
      return false;
    }

    final hasAccess = permissions.any(
      (permission) => hasPermission(permission),
    );
    if (!kReleaseMode) {
      print(
        '🔍 RBAC: hasAnyPermission check for ${permissions.join(', ')}: $hasAccess',
      );
    }
    return hasAccess;
  }

  bool hasAllPermissions(List<String> permissions) {
    if (_currentUser == null) {
      if (!kReleaseMode) {
        print(
          '⚠️ RBAC: No current user, access denied for all permissions: $permissions',
        );
      }
      return false;
    }

    final hasAccess = permissions.every(
      (permission) => hasPermission(permission),
    );
    if (!kReleaseMode) {
      print(
        '🔍 RBAC: hasAllPermissions check for ${permissions.join(', ')}: $hasAccess',
      );
    }
    return hasAccess;
  }

  List<Permission> getCurrentUserPermissions() {
    if (_currentUser == null) {
      if (!kReleaseMode) {
        print('⚠️ RBAC: No current user, returning empty permissions');
      }
      return [];
    }

    final permissions = _roleManager.getPermissionsForRole(_currentUser!.role);
    if (!kReleaseMode) {
      print(
        '📋 RBAC: Current user permissions: ${permissions.map((p) => p.id).join(', ')}',
      );
    }
    return permissions;
  }

  // Security statistics
  Map<String, dynamic> getSecurityStatistics() {
    return {
      'current_user': _currentUser?.email,
      'current_role': _currentUser?.role.toString(),
      'access_statistics': {
        'total_attempts': _accessAttempts,
        'denied_attempts': _deniedAttempts,
        'success_rate':
            _accessAttempts > 0
                ? '${(((_accessAttempts - _deniedAttempts) / _accessAttempts) * 100).toStringAsFixed(1)}%'
                : '0.0%',
      },
      'permission_usage': _permissionAccessCount,
    };
  }

  Map<String, dynamic> performSecurityHealthCheck() {
    final score = _calculateHealthScore();
    return {
      'health_score': score,
      'status':
          score >= 80
              ? 'healthy'
              : score >= 60
              ? 'fair'
              : 'poor',
      'checks': {
        'user_authenticated': _currentUser != null,
        'role_assigned': _currentUser?.role != null,
        'permissions_available': getCurrentUserPermissions().isNotEmpty,
        'access_success_rate':
            _accessAttempts > 0
                ? ((_accessAttempts - _deniedAttempts) / _accessAttempts * 100)
                : 0,
      },
    };
  }

  int _calculateHealthScore() {
    int score = 0;

    // User authenticated (40 points)
    if (_currentUser != null) score += 40;

    // Role assigned (20 points)
    if (_currentUser?.role != null) score += 20;

    // Has permissions (20 points)
    if (getCurrentUserPermissions().isNotEmpty) score += 20;

    // Good access success rate (20 points)
    if (_accessAttempts > 0) {
      final successRate = (_accessAttempts - _deniedAttempts) / _accessAttempts;
      score += (successRate * 20).round();
    }

    return score.clamp(0, 100);
  }

  // Helper method for debug
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

  // Helper methods for role checking
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isEditor => _currentUser?.role == UserRole.editor;
  bool get isUser => _currentUser?.role == UserRole.user;
  bool get isGuest => _currentUser?.role == UserRole.guest;

  // Clear security context
  void clearSecurityContext() {
    _currentUser = null;
    _accessAttempts = 0;
    _deniedAttempts = 0;
    _permissionAccessCount.clear();
  }
}
