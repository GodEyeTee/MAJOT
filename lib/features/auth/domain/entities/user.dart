import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../../../services/rbac/role_manager.dart';

/// Enhanced User entity with comprehensive domain logic
class User extends Equatable {
  final String id;
  final String? email;
  final String? displayName;
  final UserRole role;

  const User({
    required this.id,
    this.email,
    this.displayName,
    this.role = UserRole.guest, // แก้เป็น guest
  });

  // ... ส่วนที่เหลือเหมือนเดิม ...

  /// Check if user has valid email
  bool get hasValidEmail {
    if (email == null || email!.isEmpty) return false;
    return _isValidEmail(email!);
  }

  /// Check if user has display name
  bool get hasDisplayName {
    return displayName != null && displayName!.isNotEmpty;
  }

  /// Get safe display name with fallback
  String get safeDisplayName {
    if (hasDisplayName) return displayName!;
    if (hasValidEmail) return email!.split('@')[0];
    return 'User';
  }

  /// Get user initials for avatar
  String get initials {
    if (hasDisplayName) {
      final parts = displayName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return displayName![0].toUpperCase();
    }
    if (hasValidEmail) {
      return email![0].toUpperCase();
    }
    return 'U';
  }

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is editor
  bool get isEditor => role == UserRole.editor;

  /// Check if user is regular user
  bool get isUser => role == UserRole.user;

  /// Check if user is guest
  bool get isGuest => role == UserRole.guest;

  /// Get role display name
  String get roleDisplayName => role.displayName;

  /// Get role priority
  int get rolePriority => role.priority;

  /// Check if user has higher or equal role than given role
  bool hasRoleOrHigher(UserRole requiredRole) {
    return role.hasHigherOrEqualPriorityThan(requiredRole);
  }

  /// Check if user can manage another user's role
  bool canManageRole(UserRole targetRole) {
    return role.priority > targetRole.priority;
  }

  /// Validate user data
  bool isValid() {
    // ID is required
    if (id.isEmpty) return false;

    // Email validation (if provided)
    if (email != null && email!.isNotEmpty && !_isValidEmail(email!)) {
      return false;
    }

    return true;
  }

  /// Create user with updated role
  User withRole(UserRole newRole) {
    return User(id: id, email: email, displayName: displayName, role: newRole);
  }

  /// Create user with updated display name
  User withDisplayName(String newDisplayName) {
    return User(id: id, email: email, displayName: newDisplayName, role: role);
  }

  /// Create user with updated email
  User withEmail(String newEmail) {
    return User(id: id, email: newEmail, displayName: displayName, role: role);
  }

  /// Get user summary for logging/debugging
  Map<String, dynamic> toSummary() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'safe_display_name': safeDisplayName,
      'role': role.name,
      'role_display': roleDisplayName,
      'role_priority': rolePriority,
      'initials': initials,
      'has_email': hasValidEmail,
      'has_display_name': hasDisplayName,
      'is_valid': isValid(),
    };
  }

  /// Email validation
  static bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  @override
  List<Object?> get props => [id, email, displayName, role];

  @override
  String toString() {
    if (kReleaseMode) {
      return 'User(id: $id, role: ${role.name})';
    }
    return 'User(id: $id, email: $email, displayName: $displayName, role: ${role.name})';
  }
}

/// User creation request
class CreateUserRequest {
  final String id;
  final String? email;
  final String? displayName;
  final UserRole role;

  const CreateUserRequest({
    required this.id,
    this.email,
    this.displayName,
    this.role = UserRole.guest, // แก้เป็น guest
  });

  /// Convert to User entity
  User toUser() {
    return User(id: id, email: email, displayName: displayName, role: role);
  }

  /// Validate request
  bool isValid() {
    if (id.isEmpty) return false;
    if (email != null && email!.isNotEmpty && !User._isValidEmail(email!)) {
      return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'role': role.name,
    };
  }
}

/// User update request
class UpdateUserRequest {
  final String? email;
  final String? displayName;
  final UserRole? role;

  const UpdateUserRequest({this.email, this.displayName, this.role});

  /// Check if request has any updates
  bool get hasUpdates {
    return email != null || displayName != null || role != null;
  }

  /// Apply updates to user
  User applyTo(User user) {
    return User(
      id: user.id,
      email: email ?? user.email,
      displayName: displayName ?? user.displayName,
      role: role ?? user.role,
    );
  }

  /// Validate request
  bool isValid() {
    if (email != null && email!.isNotEmpty && !User._isValidEmail(email!)) {
      return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (email != null) json['email'] = email;
    if (displayName != null) json['display_name'] = displayName;
    if (role != null) json['role'] = role!.name;
    return json;
  }
}

/// User query parameters
class UserQuery {
  final String? email;
  final UserRole? role;
  final String? searchTerm;
  final int? limit;
  final int? offset;
  final UserSortBy sortBy;
  final SortOrder sortOrder;

  const UserQuery({
    this.email,
    this.role,
    this.searchTerm,
    this.limit,
    this.offset,
    this.sortBy = UserSortBy.createdAt,
    this.sortOrder = SortOrder.descending,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'role': role?.name,
      'search_term': searchTerm,
      'limit': limit,
      'offset': offset,
      'sort_by': sortBy.name,
      'sort_order': sortOrder.name,
    };
  }
}

/// User sorting options
enum UserSortBy { createdAt, updatedAt, email, displayName, role }

/// Sort order options
enum SortOrder { ascending, descending }

/// User statistics
class UserStatistics {
  final int totalUsers;
  final Map<UserRole, int> usersByRole;
  final int activeUsers;
  final int verifiedUsers;
  final DateTime lastUpdated;

  const UserStatistics({
    required this.totalUsers,
    required this.usersByRole,
    required this.activeUsers,
    required this.verifiedUsers,
    required this.lastUpdated,
  });

  /// Get percentage of users by role
  double getPercentageByRole(UserRole role) {
    if (totalUsers == 0) return 0.0;
    final count = usersByRole[role] ?? 0;
    return (count / totalUsers) * 100;
  }

  /// Get verification rate
  double get verificationRate {
    if (totalUsers == 0) return 0.0;
    return (verifiedUsers / totalUsers) * 100;
  }

  /// Get activity rate
  double get activityRate {
    if (totalUsers == 0) return 0.0;
    return (activeUsers / totalUsers) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'total_users': totalUsers,
      'users_by_role': usersByRole.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'active_users': activeUsers,
      'verified_users': verifiedUsers,
      'verification_rate': verificationRate,
      'activity_rate': activityRate,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

/// User activity log entry
class UserActivityLog {
  final String userId;
  final String action;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;

  const UserActivityLog({
    required this.userId,
    required this.action,
    this.description,
    this.metadata,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'action': action,
      'description': description,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'ip_address': ipAddress,
      'user_agent': userAgent,
    };
  }

  factory UserActivityLog.fromJson(Map<String, dynamic> json) {
    return UserActivityLog(
      userId: json['user_id'],
      action: json['action'],
      description: json['description'],
      metadata: json['metadata'],
      timestamp: DateTime.parse(json['timestamp']),
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
    );
  }
}

/// User session information
class UserSession {
  final String userId;
  final String sessionId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceInfo;
  final bool isActive;

  const UserSession({
    required this.userId,
    required this.sessionId,
    required this.createdAt,
    this.expiresAt,
    this.ipAddress,
    this.userAgent,
    this.deviceInfo,
    this.isActive = true,
  });

  /// Check if session is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if session is valid
  bool get isValid {
    return isActive && !isExpired;
  }

  /// Get remaining session time
  Duration? get remainingTime {
    if (expiresAt == null) return null;
    if (isExpired) return Duration.zero;
    return expiresAt!.difference(DateTime.now());
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'session_id': sessionId,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'device_info': deviceInfo,
      'is_active': isActive,
      'is_expired': isExpired,
      'is_valid': isValid,
    };
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: json['user_id'],
      sessionId: json['session_id'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt:
          json['expires_at'] != null
              ? DateTime.parse(json['expires_at'])
              : null,
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
      deviceInfo: json['device_info'],
      isActive: json['is_active'] ?? true,
    );
  }
}
