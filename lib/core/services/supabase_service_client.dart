import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_config_loader.dart';

/// Service client สำหรับ operations ที่ต้อง bypass RLS
class SupabaseServiceClient {
  static final SupabaseServiceClient _instance =
      SupabaseServiceClient._internal();
  factory SupabaseServiceClient() => _instance;
  SupabaseServiceClient._internal();

  SupabaseClient? _serviceClient;
  bool _isInitialized = false;

  /// Initialize service client with service role key
  Future<void> initialize(AppConfig config) async {
    if (_isInitialized) return;

    try {
      if (config.serviceRoleKey == null) {
        throw Exception('Service role key not configured');
      }

      // สร้าง client ใหม่ด้วย service role key (แบบง่าย)
      _serviceClient = SupabaseClient(
        config.supabaseUrl,
        config.serviceRoleKey!, // ใช้ service key แทน anon key
      );

      _isInitialized = true;

      if (!kReleaseMode) {
        print('✅ Supabase Service Client initialized');
        print('   URL: ${_maskUrl(config.supabaseUrl)}');
        print('   Service Key: ${_maskKey(config.serviceRoleKey!)}');
      }
    } catch (e) {
      if (!kReleaseMode) {
        print('❌ Failed to initialize Supabase Service Client: $e');
      }
      rethrow;
    }
  }

  /// Get service client instance
  SupabaseClient get client {
    if (!_isInitialized || _serviceClient == null) {
      throw Exception(
        'Supabase Service Client not initialized. Call initialize() first.',
      );
    }
    return _serviceClient!;
  }

  /// Check if service client is initialized
  bool get isInitialized => _isInitialized;

  /// Test service client connection
  Future<bool> testConnection() async {
    try {
      if (!_isInitialized) return false;

      // Test ด้วยการ query table users (ไม่เก็บ response)
      await _serviceClient!.from('users').select('id').limit(1);

      if (!kReleaseMode) {
        print('✅ Service client connection test successful');
      }
      return true;
    } catch (e) {
      if (!kReleaseMode) {
        print('❌ Service client connection test failed: $e');
      }
      return false;
    }
  }

  /// Get service client health status
  Map<String, dynamic> getHealthStatus() {
    return {
      'initialized': _isInitialized,
      'client_available': _serviceClient != null,
      'service_type': 'service_role',
      'bypass_rls': true,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Mask URL for logging
  String _maskUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      if (host.length > 10) {
        return '${uri.scheme}://${host.substring(0, 5)}***${host.substring(host.length - 3)}';
      }
      return '${uri.scheme}://$host';
    } catch (e) {
      return '[INVALID_URL]';
    }
  }

  /// Mask key for logging
  String _maskKey(String key) {
    if (key.length > 8) {
      return '${key.substring(0, 8)}***${key.substring(key.length - 8)}';
    }
    return '[SHORT_KEY]';
  }

  /// Dispose service client
  void dispose() {
    _serviceClient?.dispose();
    _serviceClient = null;
    _isInitialized = false;

    if (!kReleaseMode) {
      print('🧹 Supabase Service Client disposed');
    }
  }
}
