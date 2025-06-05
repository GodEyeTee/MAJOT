import 'package:equatable/equatable.dart';

class SecuritySettings extends Equatable {
  final String userId;
  final bool twoFactorEnabled;
  final bool biometricEnabled;
  final DateTime? lastPasswordChange;
  final List<LoginHistory> loginHistory;
  final List<ConnectedDevice> connectedDevices;
  final PrivacyPreferences privacyPreferences;

  const SecuritySettings({
    required this.userId,
    this.twoFactorEnabled = false,
    this.biometricEnabled = false,
    this.lastPasswordChange,
    this.loginHistory = const [],
    this.connectedDevices = const [],
    required this.privacyPreferences,
  });

  @override
  List<Object?> get props => [
    userId,
    twoFactorEnabled,
    biometricEnabled,
    lastPasswordChange,
    loginHistory,
    connectedDevices,
    privacyPreferences,
  ];
}

class LoginHistory extends Equatable {
  final String id;
  final DateTime timestamp;
  final String device;
  final String location;
  final String ipAddress;
  final bool isSuccessful;

  const LoginHistory({
    required this.id,
    required this.timestamp,
    required this.device,
    required this.location,
    required this.ipAddress,
    required this.isSuccessful,
  });

  @override
  List<Object> get props => [
    id,
    timestamp,
    device,
    location,
    ipAddress,
    isSuccessful,
  ];
}

class ConnectedDevice extends Equatable {
  final String id;
  final String name;
  final String type;
  final DateTime lastActive;
  final bool isCurrent;

  const ConnectedDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.lastActive,
    required this.isCurrent,
  });

  @override
  List<Object> get props => [id, name, type, lastActive, isCurrent];
}

class PrivacyPreferences extends Equatable {
  final bool showEmail;
  final bool showPhone;
  final bool showProfile;
  final bool allowAnalytics;
  final bool allowMarketing;

  const PrivacyPreferences({
    this.showEmail = false,
    this.showPhone = false,
    this.showProfile = true,
    this.allowAnalytics = true,
    this.allowMarketing = false,
  });

  PrivacyPreferences copyWith({
    bool? showEmail,
    bool? showPhone,
    bool? showProfile,
    bool? allowAnalytics,
    bool? allowMarketing,
  }) {
    return PrivacyPreferences(
      showEmail: showEmail ?? this.showEmail,
      showPhone: showPhone ?? this.showPhone,
      showProfile: showProfile ?? this.showProfile,
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      allowMarketing: allowMarketing ?? this.allowMarketing,
    );
  }

  @override
  List<Object> get props => [
    showEmail,
    showPhone,
    showProfile,
    allowAnalytics,
    allowMarketing,
  ];
}
