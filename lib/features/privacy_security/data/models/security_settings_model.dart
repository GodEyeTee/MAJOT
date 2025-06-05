import '../../domain/entities/security_settings.dart';

class SecuritySettingsModel extends SecuritySettings {
  const SecuritySettingsModel({
    required super.userId,
    super.twoFactorEnabled,
    super.biometricEnabled,
    super.lastPasswordChange,
    super.loginHistory,
    super.connectedDevices,
    required super.privacyPreferences,
  });

  factory SecuritySettingsModel.fromJson(Map<String, dynamic> json) {
    return SecuritySettingsModel(
      userId: json['user_id'] ?? '',
      twoFactorEnabled: json['two_factor_enabled'] ?? false,
      biometricEnabled: json['biometric_enabled'] ?? false,
      lastPasswordChange:
          json['last_password_change'] != null
              ? DateTime.parse(json['last_password_change'])
              : null,
      loginHistory:
          (json['login_history'] as List<dynamic>?)
              ?.map((e) => LoginHistoryModel.fromJson(e))
              .toList() ??
          [],
      connectedDevices:
          (json['connected_devices'] as List<dynamic>?)
              ?.map((e) => ConnectedDeviceModel.fromJson(e))
              .toList() ??
          [],
      privacyPreferences: PrivacyPreferencesModel.fromJson(
        json['privacy_preferences'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'two_factor_enabled': twoFactorEnabled,
      'biometric_enabled': biometricEnabled,
      'last_password_change': lastPasswordChange?.toIso8601String(),
      'privacy_preferences':
          (privacyPreferences as PrivacyPreferencesModel).toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

class LoginHistoryModel extends LoginHistory {
  const LoginHistoryModel({
    required super.id,
    required super.timestamp,
    required super.device,
    required super.location,
    required super.ipAddress,
    required super.isSuccessful,
  });

  factory LoginHistoryModel.fromJson(Map<String, dynamic> json) {
    return LoginHistoryModel(
      id: json['id'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      device: json['device'] ?? '',
      location: json['location'] ?? '',
      ipAddress: json['ip_address'] ?? '',
      isSuccessful: json['is_successful'] ?? true,
    );
  }
}

class ConnectedDeviceModel extends ConnectedDevice {
  const ConnectedDeviceModel({
    required super.id,
    required super.name,
    required super.type,
    required super.lastActive,
    required super.isCurrent,
  });

  factory ConnectedDeviceModel.fromJson(Map<String, dynamic> json) {
    return ConnectedDeviceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      lastActive: DateTime.parse(json['last_active']),
      isCurrent: json['is_current'] ?? false,
    );
  }
}

class PrivacyPreferencesModel extends PrivacyPreferences {
  const PrivacyPreferencesModel({
    super.showEmail,
    super.showPhone,
    super.showProfile,
    super.allowAnalytics,
    super.allowMarketing,
  });

  factory PrivacyPreferencesModel.fromJson(Map<String, dynamic> json) {
    return PrivacyPreferencesModel(
      showEmail: json['show_email'] ?? false,
      showPhone: json['show_phone'] ?? false,
      showProfile: json['show_profile'] ?? true,
      allowAnalytics: json['allow_analytics'] ?? true,
      allowMarketing: json['allow_marketing'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'show_email': showEmail,
      'show_phone': showPhone,
      'show_profile': showProfile,
      'allow_analytics': allowAnalytics,
      'allow_marketing': allowMarketing,
    };
  }
}
