import 'role_manager.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../core/services/logger_service.dart';

class RBACService {
  static final RBACService _instance = RBACService._internal();
  factory RBACService() => _instance;
  RBACService._internal();

  final RoleManager _roleManager = RoleManager();
  User? _currentUser;

  // Security monitoring
  int _accessAttempts = 0;
  int _deniedAttempts = 0;

  void setCurrentUser(User? user) {
    _currentUser = user;
    LoggerService.info(
      'Current user set: ${user?.email} (${user?.role})',
      'RBAC',
    );
  }

  User? get currentUser => _currentUser;

  bool hasPermission(String permissionId) {
    _accessAttempts++;

    if (_currentUser == null) {
      _deniedAttempts++;
      LoggerService.warning(
        'No current user, permission denied: $permissionId',
        'RBAC',
      );
      return false;
    }

    final hasAccess = _roleManager.hasPermission(
      _currentUser!.role,
      permissionId,
    );

    if (!hasAccess) {
      _deniedAttempts++;
      LoggerService.warning(
        'Permission denied for ${_currentUser!.email}: $permissionId',
        'RBAC',
      );
    }

    return hasAccess;
  }

  bool hasAnyPermission(List<String> permissions) {
    if (_currentUser == null) {
      LoggerService.warning(
        'No current user, access denied for permissions: $permissions',
        'RBAC',
      );
      return false;
    }

    return permissions.any((permission) => hasPermission(permission));
  }

  bool hasAllPermissions(List<String> permissions) {
    if (_currentUser == null) {
      LoggerService.warning(
        'No current user, access denied for all permissions: $permissions',
        'RBAC',
      );
      return false;
    }

    return permissions.every((permission) => hasPermission(permission));
  }

  List<Permission> getCurrentUserPermissions() {
    if (_currentUser == null) {
      return [];
    }

    return _roleManager.getPermissionsForRole(_currentUser!.role);
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

    if (_currentUser != null) score += 40;
    if (_currentUser?.role != null) score += 20;
    if (getCurrentUserPermissions().isNotEmpty) score += 20;

    if (_accessAttempts > 0) {
      final successRate = (_accessAttempts - _deniedAttempts) / _accessAttempts;
      score += (successRate * 20).round();
    }

    return score.clamp(0, 100);
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
    LoggerService.info('Security context cleared', 'RBAC');
  }
}
