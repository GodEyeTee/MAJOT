import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/logger_service.dart';
import '../models/security_settings_model.dart';

abstract class SecurityRemoteDataSource {
  Future<SecuritySettingsModel> getSecuritySettings(String userId);
  Future<void> updateSecuritySettings(SecuritySettingsModel settings);
  Future<List<LoginHistoryModel>> getLoginHistory(String userId);
  Future<List<ConnectedDeviceModel>> getConnectedDevices(String userId);
  Future<void> revokeDevice(String deviceId);
}

class SecurityRemoteDataSourceImpl implements SecurityRemoteDataSource {
  final SupabaseClient supabaseClient;

  SecurityRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<SecuritySettingsModel> getSecuritySettings(String userId) async {
    try {
      LoggerService.info(
        'Getting security settings for user: $userId',
        'SECURITY_DS',
      );

      // ลองดึงข้อมูลจาก security_settings table
      final response =
          await supabaseClient
              .from('security_settings')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

      // ถ้าไม่มีข้อมูล ให้สร้างใหม่
      if (response == null) {
        LoggerService.info(
          'Security settings not found, creating new',
          'SECURITY_DS',
        );

        final newSettings = {
          'user_id': userId,
          'two_factor_enabled': false,
          'biometric_enabled': false,
          'privacy_preferences': {
            'show_email': false,
            'show_phone': false,
            'show_profile': true,
            'allow_analytics': true,
            'allow_marketing': false,
          },
        };

        await supabaseClient.from('security_settings').insert(newSettings);

        // ดึงข้อมูลที่สร้างใหม่
        final createdResponse =
            await supabaseClient
                .from('security_settings')
                .select()
                .eq('user_id', userId)
                .single();

        // Get login history และ connected devices
        final loginHistory = await getLoginHistory(userId);
        final connectedDevices = await getConnectedDevices(userId);

        final settingsData = {
          ...createdResponse,
          'login_history':
              loginHistory
                  .map(
                    (e) => {
                      'id': e.id,
                      'timestamp': e.timestamp.toIso8601String(),
                      'device': e.device,
                      'location': e.location,
                      'ip_address': e.ipAddress,
                      'is_successful': e.isSuccessful,
                    },
                  )
                  .toList(),
          'connected_devices':
              connectedDevices
                  .map(
                    (e) => {
                      'id': e.id,
                      'name': e.name,
                      'type': e.type,
                      'last_active': e.lastActive.toIso8601String(),
                      'is_current': e.isCurrent,
                    },
                  )
                  .toList(),
        };

        LoggerService.info(
          'Security settings created successfully',
          'SECURITY_DS',
        );
        return SecuritySettingsModel.fromJson(settingsData);
      }

      // Get login history และ connected devices
      final loginHistory = await getLoginHistory(userId);
      final connectedDevices = await getConnectedDevices(userId);

      final settingsData = {
        ...response,
        'login_history':
            loginHistory
                .map(
                  (e) => {
                    'id': e.id,
                    'timestamp': e.timestamp.toIso8601String(),
                    'device': e.device,
                    'location': e.location,
                    'ip_address': e.ipAddress,
                    'is_successful': e.isSuccessful,
                  },
                )
                .toList(),
        'connected_devices':
            connectedDevices
                .map(
                  (e) => {
                    'id': e.id,
                    'name': e.name,
                    'type': e.type,
                    'last_active': e.lastActive.toIso8601String(),
                    'is_current': e.isCurrent,
                  },
                )
                .toList(),
      };

      LoggerService.info(
        'Security settings retrieved successfully',
        'SECURITY_DS',
      );
      return SecuritySettingsModel.fromJson(settingsData);
    } catch (e) {
      LoggerService.error('Failed to get security settings', 'SECURITY_DS', e);

      // Return default settings on error
      return SecuritySettingsModel(
        userId: userId,
        privacyPreferences: const PrivacyPreferencesModel(),
        loginHistory: [],
        connectedDevices: [],
      );
    }
  }

  @override
  Future<void> updateSecuritySettings(SecuritySettingsModel settings) async {
    try {
      LoggerService.info('Updating security settings', 'SECURITY_DS');

      // ตรวจสอบว่ามี settings อยู่แล้วหรือไม่
      final existing =
          await supabaseClient
              .from('security_settings')
              .select()
              .eq('user_id', settings.userId)
              .maybeSingle();

      if (existing == null) {
        // ถ้าไม่มีให้สร้างใหม่
        await supabaseClient
            .from('security_settings')
            .insert(settings.toJson());
      } else {
        // ถ้ามีให้ update
        await supabaseClient
            .from('security_settings')
            .update(settings.toJson())
            .eq('user_id', settings.userId);
      }

      LoggerService.info(
        'Security settings updated successfully',
        'SECURITY_DS',
      );
    } catch (e) {
      LoggerService.error(
        'Failed to update security settings',
        'SECURITY_DS',
        e,
      );
      throw ServerException('Failed to update security settings');
    }
  }

  @override
  Future<List<LoginHistoryModel>> getLoginHistory(String userId) async {
    try {
      final response = await supabaseClient
          .from('login_history')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(10);

      return (response as List)
          .map((e) => LoginHistoryModel.fromJson(e))
          .toList();
    } catch (e) {
      LoggerService.warning('Failed to get login history', 'SECURITY_DS');
      return [];
    }
  }

  @override
  Future<List<ConnectedDeviceModel>> getConnectedDevices(String userId) async {
    try {
      final response = await supabaseClient
          .from('connected_devices')
          .select()
          .eq('user_id', userId)
          .order('last_active', ascending: false);

      return (response as List)
          .map((e) => ConnectedDeviceModel.fromJson(e))
          .toList();
    } catch (e) {
      LoggerService.warning('Failed to get connected devices', 'SECURITY_DS');
      return [];
    }
  }

  @override
  Future<void> revokeDevice(String deviceId) async {
    try {
      await supabaseClient
          .from('connected_devices')
          .delete()
          .eq('id', deviceId);
    } catch (e) {
      LoggerService.error('Failed to revoke device', 'SECURITY_DS', e);
      throw ServerException('Failed to revoke device');
    }
  }
}
