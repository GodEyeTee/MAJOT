import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_config_loader.dart';
import 'logger_service.dart';

class SupabaseServiceClient {
  static final SupabaseServiceClient _instance =
      SupabaseServiceClient._internal();
  factory SupabaseServiceClient() => _instance;
  SupabaseServiceClient._internal();

  SupabaseClient? _serviceClient;
  bool _isInitialized = false;

  Future<void> initialize(AppConfig config) async {
    if (_isInitialized) {
      LoggerService.info(
        'Service client already initialized',
        'SUPABASE_SERVICE',
      );
      return;
    }

    try {
      if (config.serviceRoleKey == null || config.serviceRoleKey!.isEmpty) {
        throw Exception('Service role key not configured');
      }

      // สร้าง service client ด้วย service role key
      _serviceClient = SupabaseClient(
        config.supabaseUrl,
        config.serviceRoleKey!,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

      _isInitialized = true;

      LoggerService.info(
        'Supabase Service Client initialized successfully',
        'SUPABASE_SERVICE',
      );
    } catch (e) {
      LoggerService.error(
        'Failed to initialize Supabase Service Client',
        'SUPABASE_SERVICE',
        e,
      );
      rethrow;
    }
  }

  SupabaseClient get client {
    if (!_isInitialized || _serviceClient == null) {
      throw Exception(
        'Supabase Service Client not initialized. Call initialize() first.',
      );
    }
    return _serviceClient!;
  }

  bool get isInitialized => _isInitialized;

  Future<bool> testConnection() async {
    try {
      if (!_isInitialized) return false;

      // Test query - service role should bypass RLS
      await _serviceClient!.from('users').select('id').limit(1);

      LoggerService.info(
        'Service client connection test successful',
        'SUPABASE_SERVICE',
      );
      return true;
    } catch (e) {
      LoggerService.error(
        'Service client connection test failed',
        'SUPABASE_SERVICE',
        e,
      );
      return false;
    }
  }

  Map<String, dynamic> getHealthStatus() {
    return {
      'initialized': _isInitialized,
      'client_available': _serviceClient != null,
      'service_type': 'service_role',
      'bypass_rls': true,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  void dispose() {
    _serviceClient?.dispose();
    _serviceClient = null;
    _isInitialized = false;
    LoggerService.info('Supabase Service Client disposed', 'SUPABASE_SERVICE');
  }
}
