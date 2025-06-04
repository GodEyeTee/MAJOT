import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/app_config_loader.dart';
import 'core/services/supabase_service_client.dart';
import 'core/di/injection_container.dart' as di;
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initializeApp();
    runApp(const App());
  } catch (e) {
    print('❌ App initialization failed: $e');
    runApp(_buildErrorApp(e.toString()));
  }
}

Future<void> _initializeApp() async {
  print('🚀 Starting app initialization...');

  // Initialize Firebase
  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp();
  print('✅ Firebase initialized');

  // Load app configuration
  print('📋 Loading app configuration...');
  AppConfig config;
  try {
    config = await AppConfig.fromAsset();
    print('✅ Configuration loaded from assets');
  } catch (e) {
    print('⚠️ Failed to load config from assets: $e');
    print('🔄 Using default configuration');
    config = _createDefaultConfig();
  }

  // Validate service role key
  if (config.serviceRoleKey == null || config.serviceRoleKey!.isEmpty) {
    print('⚠️ Service role key not configured, using anon key only');
  } else {
    print('✅ Service role key configured');
  }

  // Initialize Supabase (regular client)
  print('🗄️ Initializing Supabase client...');
  await Supabase.initialize(url: config.supabaseUrl, anonKey: config.anonKey);
  print('✅ Supabase client initialized');

  // Initialize Supabase Service Client (for RLS bypass)
  if (config.serviceRoleKey != null && config.serviceRoleKey!.isNotEmpty) {
    print('🔐 Initializing Supabase Service Client...');
    try {
      await SupabaseServiceClient().initialize(config);
      print('✅ Supabase Service Client initialized');

      // Test service connection
      final connectionOk = await SupabaseServiceClient().testConnection();
      print(
        connectionOk
            ? '✅ Service client connection test passed'
            : '⚠️ Service client connection test failed',
      );
    } catch (e) {
      print('❌ Failed to initialize Service Client: $e');
      print('⚠️ Will continue with regular client only');
    }
  }

  // Initialize DI
  print('🔧 Initializing dependency injection...');
  await di.init();
  print('✅ Dependency injection initialized');

  print('🎉 App initialization completed successfully!');
}

AppConfig _createDefaultConfig() {
  return AppConfig(
    supabaseUrl: 'https://localhost.supabase.co',
    anonKey:
        'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvY2FsaG9zdCIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNjQxNzY5MjAwLCJleHAiOjE5NTczNDUyMDB9.default-anon-key',
    serviceRoleKey: null, // No service key in fallback config
    environment: 'development',
    version: '1.0.0-dev',
    features: {
      'analytics_enabled': false,
      'crash_reporting_enabled': false,
      'debug_mode_enabled': true,
      'offline_mode_enabled': true,
      'performance_monitoring_enabled': false,
      'security_logging_enabled': true,
    },
    security: {
      'session_timeout_minutes': 60,
      'max_login_attempts': 10,
      'require_secure_connection': false,
      'certificate_pinning_enabled': false,
      'api_rate_limiting_enabled': false,
      'encryption_enabled': false,
    },
    performance: {
      'api_timeout_seconds': 60,
      'cache_duration_minutes': 5,
      'concurrent_requests_limit': 10,
      'preload_enabled': false,
      'compression_enabled': false,
    },
  );
}

Widget _buildErrorApp(String error) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Initialization Failed',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
