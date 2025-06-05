import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/security_settings.dart';
import '../../domain/usecases/get_security_settings.dart';
import '../../domain/repositories/security_repository.dart';
import 'security_event.dart';
import 'security_state.dart';

class SecurityBloc extends Bloc<SecurityEvent, SecurityState> {
  final GetSecuritySettings getSecuritySettingsUseCase;
  final SecurityRepository repository;

  SecurityBloc({
    required this.getSecuritySettingsUseCase,
    required this.repository,
  }) : super(SecurityInitial()) {
    on<LoadSecuritySettingsEvent>(_onLoadSecuritySettings);
    on<UpdatePrivacyPreferencesEvent>(_onUpdatePrivacyPreferences);
    on<ToggleTwoFactorEvent>(_onToggleTwoFactor);
    on<ToggleBiometricEvent>(_onToggleBiometric);
    on<RevokeDeviceEvent>(_onRevokeDevice);
  }

  Future<void> _onLoadSecuritySettings(
    LoadSecuritySettingsEvent event,
    Emitter<SecurityState> emit,
  ) async {
    emit(SecurityLoading());

    final result = await getSecuritySettingsUseCase(event.userId);

    result.fold(
      (failure) => emit(SecurityError(failure.message)),
      (settings) => emit(SecurityLoaded(settings)),
    );
  }

  Future<void> _onUpdatePrivacyPreferences(
    UpdatePrivacyPreferencesEvent event,
    Emitter<SecurityState> emit,
  ) async {
    if (state is SecurityLoaded) {
      final currentState = state as SecurityLoaded;
      final updatedSettings = SecuritySettings(
        userId: currentState.settings.userId,
        twoFactorEnabled: currentState.settings.twoFactorEnabled,
        biometricEnabled: currentState.settings.biometricEnabled,
        lastPasswordChange: currentState.settings.lastPasswordChange,
        loginHistory: currentState.settings.loginHistory,
        connectedDevices: currentState.settings.connectedDevices,
        privacyPreferences: event.preferences,
      );

      final result = await repository.updateSecuritySettings(updatedSettings);

      result.fold(
        (failure) => emit(SecurityError(failure.message)),
        (_) => emit(SecurityLoaded(updatedSettings)),
      );
    }
  }

  Future<void> _onToggleTwoFactor(
    ToggleTwoFactorEvent event,
    Emitter<SecurityState> emit,
  ) async {
    // Implementation
  }

  Future<void> _onToggleBiometric(
    ToggleBiometricEvent event,
    Emitter<SecurityState> emit,
  ) async {
    // Implementation
  }

  Future<void> _onRevokeDevice(
    RevokeDeviceEvent event,
    Emitter<SecurityState> emit,
  ) async {
    final result = await repository.revokeDevice(event.deviceId);

    result.fold((failure) => emit(SecurityError(failure.message)), (_) {
      if (state is SecurityLoaded) {
        add(
          LoadSecuritySettingsEvent((state as SecurityLoaded).settings.userId),
        );
      }
    });
  }
}
