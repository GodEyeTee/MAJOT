import 'package:my_test_app/features/auth/data/models/user_model.dart';
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

abstract class SupabaseUserDataSource {
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser(String id);
  Future<void> updateUserRole(String id, String role);
  Future<bool> validateConnection();
  Future<void> saveLoginHistory(Map<String, dynamic> loginData);
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

      final response =
          await supabaseClient
              .rpc(
                'get_or_create_security_settings',
                params: {'p_user_id': userId},
              )
              .single();

      // Get login history
      final loginHistory = await getLoginHistory(userId);

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
        'connected_devices': [],
      };

      LoggerService.info(
        'Security settings retrieved successfully',
        'SECURITY_DS',
      );
      return SecuritySettingsModel.fromJson(settingsData);
    } catch (e) {
      LoggerService.error('Failed to get security settings', 'SECURITY_DS', e);
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

      await supabaseClient.rpc(
        'update_security_settings',
        params: {
          'p_user_id': settings.userId,
          'p_biometric_enabled': settings.biometricEnabled,
          'p_privacy_preferences':
              (settings.privacyPreferences as PrivacyPreferencesModel).toJson(),
        },
      );

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
      throw ServerException(
        'Failed to update security settings: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<LoginHistoryModel>> getLoginHistory(String userId) async {
    try {
      LoggerService.info(
        'Getting login history for user: $userId',
        'SECURITY_DS',
      );

      final response = await supabaseClient
          .from('login_history')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(10);

      if ((response as List).isEmpty) {
        LoggerService.info('No login history found', 'SECURITY_DS');
        return [];
      }

      final history =
          (response as List).map((e) => LoginHistoryModel.fromJson(e)).toList();

      LoggerService.info(
        'Retrieved ${history.length} login history entries',
        'SECURITY_DS',
      );
      return history;
    } catch (e) {
      LoggerService.warning('Failed to get login history: $e', 'SECURITY_DS');
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
