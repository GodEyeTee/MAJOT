import 'package:flutter/material.dart';
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
  }

  User? get currentUser => _currentUser;

  bool hasPermission(String permissionId) {
    if (_currentUser == null) return false;
    return _roleManager.hasPermission(_currentUser!.role, permissionId);
  }

  bool hasAnyPermission(List<String> permissions) {
    return permissions.any((permission) => hasPermission(permission));
  }

  List<Permission> getCurrentUserPermissions() {
    if (_currentUser == null) return [];
    return _roleManager.getPermissionsForRole(_currentUser!.role);
  }
}
