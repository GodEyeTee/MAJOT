import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import '../../domain/entities/user.dart';
import '../../../../services/rbac/role_manager.dart';

/// Enhanced user model with comprehensive data management and security features
class UserModel extends User {
  final String? photoURL;
  final bool emailVerified;
  final String? phoneNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic> metadata;
  final bool isActive;
  final String? provider;
  final List<String> linkedProviders;

  const UserModel({
    required super.id,
    super.email,
    super.displayName,
    super.role = UserRole.user,
    this.photoURL,
    this.emailVerified = false,
    this.phoneNumber,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.metadata = const {},
    this.isActive = true,
    this.provider,
    this.linkedProviders = const [],
  });

  /// Create UserModel from Firebase User with enhanced data extraction
  factory UserModel.fromFirebaseUser(firebase.User user) {
    return UserModel(
      id: user.uid,
      email: user.email,
      displayName: user.displayName ?? _generateDisplayName(user.email),
      role: UserRole.user, // Default role, will be updated from Supabase
      photoURL: user.photoURL,
      emailVerified: user.emailVerified,
      phoneNumber: user.phoneNumber,
      createdAt: user.metadata.creationTime,
      lastLoginAt: user.metadata.lastSignInTime,
      updatedAt: DateTime.now(),
      provider: _extractPrimaryProvider(user),
      linkedProviders:
          user.providerData.map((info) => info.providerId).toList(),
      metadata: {
        'firebase_uid': user.uid,
        'creation_time': user.metadata.creationTime?.toIso8601String(),
        'last_signin_time': user.metadata.lastSignInTime?.toIso8601String(),
        'is_anonymous': user.isAnonymous,
        'tenant_id': user.tenantId,
      },
    );
  }

  /// Create UserModel from JSON with comprehensive validation
  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parse role with fallback
      UserRole userRole = UserRole.user;
      if (json['role'] != null) {
        final roleString = json['role'].toString().toLowerCase();
        userRole = UserRole.values.firstWhere(
          (role) => role.name.toLowerCase() == roleString,
          orElse: () => UserRole.user,
        );
      }

      // Parse timestamps safely
      DateTime? parseDateTime(dynamic value) {
        if (value == null) return null;
        if (value is String) {
          try {
            return DateTime.parse(value);
          } catch (e) {
            if (!kReleaseMode) {
              print('⚠️ Failed to parse datetime: $value');
            }
            return null;
          }
        }
        return null;
      }

      // Parse metadata with validation
      Map<String, dynamic> metadata = {};
      if (json['metadata'] is Map) {
        metadata = Map<String, dynamic>.from(json['metadata']);
      }

      // Parse linked providers
      List<String> linkedProviders = [];
      if (json['linked_providers'] is List) {
        linkedProviders = List<String>.from(json['linked_providers']);
      }

      return UserModel(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString(),
        displayName:
            json['full_name']?.toString() ??
            json['display_name']?.toString() ??
            _generateDisplayName(json['email']?.toString()),
        role: userRole,
        photoURL:
            json['photo_url']?.toString() ?? json['avatar_url']?.toString(),
        emailVerified: json['email_verified'] == true,
        phoneNumber: json['phone_number']?.toString(),
        createdAt: parseDateTime(json['created_at']),
        updatedAt: parseDateTime(json['updated_at']),
        lastLoginAt: parseDateTime(json['last_login_at']),
        metadata: metadata,
        isActive: json['is_active'] ?? true,
        provider: json['provider']?.toString(),
        linkedProviders: linkedProviders,
      );
    } catch (e) {
      if (!kReleaseMode) {
        print('❌ Error parsing UserModel from JSON: $e');
        print('JSON data: $json');
      }

      // Return basic user model with minimal data
      return UserModel(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString(),
        displayName: json['full_name']?.toString() ?? 'User',
        role: UserRole.user,
      );
    }
  }

  /// Convert to JSON with comprehensive data serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': displayName,
      'display_name': displayName,
      'role': role.name,
      'photo_url': photoURL,
      'avatar_url': photoURL,
      'email_verified': emailVerified,
      'phone_number': phoneNumber,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'metadata': metadata,
      'is_active': isActive,
      'provider': provider,
      'linked_providers': linkedProviders,
    };
  }

  /// Convert to Supabase-compatible JSON
  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'email': email,
      'full_name': displayName,
      'role': role.name,
      'photo_url': photoURL,
      'email_verified': emailVerified,
      'phone_number': phoneNumber,
      'created_at':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_active': isActive,
      'provider': provider,
      'linked_providers': linkedProviders,
      'metadata': metadata,
    };
  }

  /// Create a copy with modified values
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    UserRole? role,
    String? photoURL,
    bool? emailVerified,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? metadata,
    bool? isActive,
    String? provider,
    List<String>? linkedProviders,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
      provider: provider ?? this.provider,
      linkedProviders: linkedProviders ?? this.linkedProviders,
    );
  }

  /// Update last login timestamp
  UserModel updateLastLogin() {
    return copyWith(lastLoginAt: DateTime.now(), updatedAt: DateTime.now());
  }

  /// Update role with timestamp
  UserModel updateRole(UserRole newRole) {
    return copyWith(
      role: newRole,
      updatedAt: DateTime.now(),
      metadata: {
        ...metadata,
        'role_updated_at': DateTime.now().toIso8601String(),
        'previous_role': role.name,
      },
    );
  }

  /// Add metadata
  UserModel addMetadata(String key, dynamic value) {
    return copyWith(
      metadata: {...metadata, key: value},
      updatedAt: DateTime.now(),
    );
  }

  /// Remove metadata
  UserModel removeMetadata(String key) {
    final newMetadata = Map<String, dynamic>.from(metadata);
    newMetadata.remove(key);
    return copyWith(metadata: newMetadata, updatedAt: DateTime.now());
  }

  /// Check if user has been active recently
  bool get isRecentlyActive {
    if (lastLoginAt == null) return false;
    return DateTime.now().difference(lastLoginAt!).inDays <= 30;
  }

  /// Get user age (time since creation)
  Duration? get accountAge {
    if (createdAt == null) return null;
    return DateTime.now().difference(createdAt!);
  }

  /// Get time since last login
  Duration? get timeSinceLastLogin {
    if (lastLoginAt == null) return null;
    return DateTime.now().difference(lastLoginAt!);
  }

  /// Check if user profile is complete
  bool get isProfileComplete {
    return email != null &&
        email!.isNotEmpty &&
        displayName != null &&
        displayName!.isNotEmpty;
  }

  /// Get user initials for avatar
  String get initials {
    if (displayName == null || displayName!.isEmpty) {
      return email?.substring(0, 1).toUpperCase() ?? 'U';
    }

    final parts = displayName!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName![0].toUpperCase();
  }

  /// Get display name with fallback
  String get safeDisplayName {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (email != null && email!.isNotEmpty) {
      return email!.split('@')[0];
    }
    return 'User';
  }

  /// Check if user has verified email
  bool get hasVerifiedEmail {
    return emailVerified && email != null && email!.isNotEmpty;
  }

  /// Check if user has phone number
  bool get hasPhoneNumber {
    return phoneNumber != null && phoneNumber!.isNotEmpty;
  }

  /// Check if user has profile photo
  bool get hasProfilePhoto {
    return photoURL != null && photoURL!.isNotEmpty;
  }

  /// Get security score based on profile completeness
  int get securityScore {
    int score = 0;

    // Basic account (20 points)
    if (email != null && email!.isNotEmpty) score += 20;

    // Email verification (20 points)
    if (emailVerified) score += 20;

    // Phone number (15 points)
    if (hasPhoneNumber) score += 15;

    // Profile photo (10 points)
    if (hasProfilePhoto) score += 10;

    // Complete profile (15 points)
    if (isProfileComplete) score += 15;

    // Recent activity (10 points)
    if (isRecentlyActive) score += 10;

    // Multiple providers (10 points)
    if (linkedProviders.length > 1) score += 10;

    return score.clamp(0, 100);
  }

  /// Get user status summary
  Map<String, dynamic> getStatusSummary() {
    return {
      'id': id,
      'email': email,
      'display_name': safeDisplayName,
      'role': role.name,
      'role_display': role.displayName,
      'role_priority': role.priority,
      'email_verified': emailVerified,
      'is_active': isActive,
      'is_recently_active': isRecentlyActive,
      'profile_complete': isProfileComplete,
      'security_score': securityScore,
      'account_age_days': accountAge?.inDays,
      'days_since_login': timeSinceLastLogin?.inDays,
      'provider': provider,
      'linked_providers_count': linkedProviders.length,
      'has_phone': hasPhoneNumber,
      'has_photo': hasProfilePhoto,
    };
  }

  /// Validate user data integrity
  bool isValid() {
    try {
      // Required fields
      if (id.isEmpty) return false;

      // Email validation (if provided)
      if (email != null && email!.isNotEmpty) {
        if (!_isValidEmail(email!)) return false;
      }

      // Phone number validation (if provided)
      if (phoneNumber != null && phoneNumber!.isNotEmpty) {
        if (!_isValidPhoneNumber(phoneNumber!)) return false;
      }

      // URL validation (if provided)
      if (photoURL != null && photoURL!.isNotEmpty) {
        if (!_isValidUrl(photoURL!)) return false;
      }

      // Date validation
      if (createdAt != null && createdAt!.isAfter(DateTime.now())) return false;
      if (updatedAt != null && updatedAt!.isAfter(DateTime.now())) return false;
      if (lastLoginAt != null && lastLoginAt!.isAfter(DateTime.now()))
        return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generate display name from email
  static String _generateDisplayName(String? email) {
    if (email == null || email.isEmpty) return 'User';

    try {
      final localPart = email.split('@')[0];
      return localPart
          .split('.')
          .map(
            (part) =>
                part.isNotEmpty
                    ? part[0].toUpperCase() + part.substring(1)
                    : part,
          )
          .join(' ');
    } catch (e) {
      return 'User';
    }
  }

  /// Extract primary provider from Firebase user
  static String _extractPrimaryProvider(firebase.User user) {
    if (user.providerData.isNotEmpty) {
      return user.providerData.first.providerId;
    }
    return 'firebase';
  }

  /// Email validation
  static bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  /// Phone number validation
  static bool _isValidPhoneNumber(String phoneNumber) {
    return RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phoneNumber);
  }

  /// URL validation
  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  @override
  List<Object?> get props => [
    ...super.props,
    photoURL,
    emailVerified,
    phoneNumber,
    createdAt,
    updatedAt,
    lastLoginAt,
    metadata,
    isActive,
    provider,
    linkedProviders,
  ];

  @override
  String toString() {
    if (kReleaseMode) {
      return 'UserModel(id: $id, role: ${role.name})';
    }

    return 'UserModel('
        'id: $id, '
        'email: $email, '
        'displayName: $displayName, '
        'role: ${role.name}, '
        'emailVerified: $emailVerified, '
        'isActive: $isActive, '
        'provider: $provider, '
        'securityScore: $securityScore'
        ')';
  }
}

/// User profile update request
class UserProfileUpdateRequest {
  final String? displayName;
  final String? phoneNumber;
  final String? photoURL;
  final Map<String, dynamic>? metadata;

  const UserProfileUpdateRequest({
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (displayName != null) json['full_name'] = displayName;
    if (phoneNumber != null) json['phone_number'] = phoneNumber;
    if (photoURL != null) json['photo_url'] = photoURL;
    if (metadata != null) json['metadata'] = metadata;

    json['updated_at'] = DateTime.now().toIso8601String();

    return json;
  }

  bool get isEmpty {
    return displayName == null &&
        phoneNumber == null &&
        photoURL == null &&
        (metadata == null || metadata!.isEmpty);
  }
}

/// User role update request
class UserRoleUpdateRequest {
  final UserRole newRole;
  final String? reason;
  final String? updatedBy;

  const UserRoleUpdateRequest({
    required this.newRole,
    this.reason,
    this.updatedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': newRole.name,
      'role_updated_at': DateTime.now().toIso8601String(),
      'role_update_reason': reason,
      'role_updated_by': updatedBy,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

/// User search criteria
class UserSearchCriteria {
  final String? email;
  final UserRole? role;
  final bool? isActive;
  final bool? emailVerified;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final DateTime? lastLoginAfter;
  final DateTime? lastLoginBefore;
  final String? provider;
  final int? limit;
  final int? offset;

  const UserSearchCriteria({
    this.email,
    this.role,
    this.isActive,
    this.emailVerified,
    this.createdAfter,
    this.createdBefore,
    this.lastLoginAfter,
    this.lastLoginBefore,
    this.provider,
    this.limit,
    this.offset,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};

    if (email != null) params['email'] = email;
    if (role != null) params['role'] = role!.name;
    if (isActive != null) params['is_active'] = isActive;
    if (emailVerified != null) params['email_verified'] = emailVerified;
    if (createdAfter != null)
      params['created_after'] = createdAfter!.toIso8601String();
    if (createdBefore != null)
      params['created_before'] = createdBefore!.toIso8601String();
    if (lastLoginAfter != null)
      params['last_login_after'] = lastLoginAfter!.toIso8601String();
    if (lastLoginBefore != null)
      params['last_login_before'] = lastLoginBefore!.toIso8601String();
    if (provider != null) params['provider'] = provider;
    if (limit != null) params['limit'] = limit;
    if (offset != null) params['offset'] = offset;

    return params;
  }
}
