import 'package:equatable/equatable.dart';
import '../../domain/entities/security_settings.dart';

abstract class SecurityEvent extends Equatable {
  const SecurityEvent();

  @override
  List<Object> get props => [];
}

class LoadSecuritySettingsEvent extends SecurityEvent {
  final String userId;

  const LoadSecuritySettingsEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

class UpdatePrivacyPreferencesEvent extends SecurityEvent {
  final PrivacyPreferences preferences;

  const UpdatePrivacyPreferencesEvent(this.preferences);

  @override
  List<Object> get props => [preferences];
}

class ToggleTwoFactorEvent extends SecurityEvent {
  final bool enabled;

  const ToggleTwoFactorEvent(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class ToggleBiometricEvent extends SecurityEvent {
  final bool enabled;

  const ToggleBiometricEvent(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class RevokeDeviceEvent extends SecurityEvent {
  final String deviceId;

  const RevokeDeviceEvent(this.deviceId);

  @override
  List<Object> get props => [deviceId];
}
