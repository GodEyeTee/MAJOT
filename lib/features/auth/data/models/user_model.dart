import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';

import '../../domain/entities/user.dart';
import '../../../../services/rbac/role_manager.dart';
import '../../../../core/services/logger_service.dart';

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

  factory UserModel.fromFirebaseUser(firebase.User user) {
    return UserModel(
      id: user.uid,
      email: user.email,
      displayName: user.displayName ?? _generateDisplayName(user.email),
      role: UserRole.guest,
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
        'role_source': 'firebase_initial',
      },
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      LoggerService.debug('Parsing UserModel from JSON', 'USER_MODEL');

      UserRole userRole = UserRole.guest;
      if (json['role'] != null) {
        final roleString = json['role'].toString().toLowerCase().trim();
        userRole = UserRole.values.firstWhere(
          (role) => role.name.toLowerCase() == roleString,
          orElse: () {
            LoggerService.warning(
              'Unknown role "$roleString", defaulting to guest',
              'USER_MODEL',
            );
            return UserRole.guest;
          },
        );
      }

      DateTime? parseDateTime(dynamic value) {
        if (value == null) return null;
        if (value is String) {
          try {
            return DateTime.parse(value);
          } catch (e) {
            LoggerService.warning(
              'Failed to parse datetime: $value',
              'USER_MODEL',
            );
            return null;
          }
        }
        return null;
      }

      Map<String, dynamic> metadata = {};
      if (json['metadata'] is Map) {
        metadata = Map<String, dynamic>.from(json['metadata']);
      }

      metadata['role_source'] = 'supabase';
      metadata['parsed_at'] = DateTime.now().toIso8601String();

      List<String> linkedProviders = [];
      if (json['linked_providers'] is List) {
        linkedProviders = List<String>.from(json['linked_providers']);
      }

      final userModel = UserModel(
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

      LoggerService.info(
        'Successfully parsed UserModel with role: ${userModel.role}',
        'USER_MODEL',
      );
      return userModel;
    } catch (e) {
      LoggerService.error('Error parsing UserModel from JSON', 'USER_MODEL', e);

      return UserModel(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString(),
        displayName: json['full_name']?.toString() ?? 'User',
        role: UserRole.guest,
        metadata: {
          'parse_error': e.toString(),
          'role_source': 'error_fallback',
        },
      );
    }
  }

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

  UserModel updateLastLogin() {
    return copyWith(lastLoginAt: DateTime.now(), updatedAt: DateTime.now());
  }

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

  UserModel addMetadata(String key, dynamic value) {
    return copyWith(
      metadata: {...metadata, key: value},
      updatedAt: DateTime.now(),
    );
  }

  bool get isRecentlyActive {
    if (lastLoginAt == null) return false;
    return DateTime.now().difference(lastLoginAt!).inDays <= 30;
  }

  Duration? get accountAge {
    if (createdAt == null) return null;
    return DateTime.now().difference(createdAt!);
  }

  Duration? get timeSinceLastLogin {
    if (lastLoginAt == null) return null;
    return DateTime.now().difference(lastLoginAt!);
  }

  bool get isProfileComplete {
    return email != null &&
        email!.isNotEmpty &&
        displayName != null &&
        displayName!.isNotEmpty;
  }

  @override
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

  @override
  String get safeDisplayName {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (email != null && email!.isNotEmpty) {
      return email!.split('@')[0];
    }
    return 'User';
  }

  bool get hasVerifiedEmail {
    return emailVerified && email != null && email!.isNotEmpty;
  }

  bool get hasPhoneNumber {
    return phoneNumber != null && phoneNumber!.isNotEmpty;
  }

  bool get hasProfilePhoto {
    return photoURL != null && photoURL!.isNotEmpty;
  }

  int get securityScore {
    int score = 0;

    if (email != null && email!.isNotEmpty) score += 20;
    if (emailVerified) score += 20;
    if (hasPhoneNumber) score += 15;
    if (hasProfilePhoto) score += 10;
    if (isProfileComplete) score += 15;
    if (isRecentlyActive) score += 10;
    if (linkedProviders.length > 1) score += 10;

    return score.clamp(0, 100);
  }

  @override
  bool isValid() {
    try {
      if (id.isEmpty) {
        return false;
      }

      if (email != null && email!.isNotEmpty) {
        if (!_isValidEmail(email!)) {
          return false;
        }
      }

      if (phoneNumber != null && phoneNumber!.isNotEmpty) {
        if (!_isValidPhoneNumber(phoneNumber!)) {
          return false;
        }
      }

      if (photoURL != null && photoURL!.isNotEmpty) {
        if (!_isValidUrl(photoURL!)) {
          return false;
        }
      }

      if (createdAt != null && createdAt!.isAfter(DateTime.now())) {
        return false;
      }

      if (updatedAt != null && updatedAt!.isAfter(DateTime.now())) {
        return false;
      }

      if (lastLoginAt != null && lastLoginAt!.isAfter(DateTime.now())) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

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

  static String _extractPrimaryProvider(firebase.User user) {
    if (user.providerData.isNotEmpty) {
      return user.providerData.first.providerId;
    }
    return 'firebase';
  }

  static bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  static bool _isValidPhoneNumber(String phoneNumber) {
    return RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phoneNumber);
  }

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

    return 'UserModel(id: $id, email: $email, displayName: $displayName, role: ${role.name}, emailVerified: $emailVerified, isActive: $isActive, provider: $provider, securityScore: $securityScore)';
  }
}
