import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/utils/app_config_loader.dart';
import 'core/services/supabase_service_client.dart';
import 'core/services/logger_service.dart';
import 'core/di/injection_container.dart' as di;
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initializeApp();
    runApp(const App());
  } catch (e) {
    LoggerService.error('App initialization failed', 'MAIN', e);
    runApp(_buildErrorApp(e.toString()));
  }
}

Future<void> _initializeApp() async {
  LoggerService.info('Starting app initialization', 'MAIN');

  // Initialize Firebase
  LoggerService.info('Initializing Firebase', 'FIREBASE');
  await Firebase.initializeApp();
  LoggerService.info('Firebase initialized successfully', 'FIREBASE');

  // Load app configuration
  LoggerService.info('Loading app configuration', 'CONFIG');
  AppConfig config;
  try {
    config = await AppConfig.fromAsset();
    LoggerService.info('Configuration loaded from assets', 'CONFIG');
  } catch (e) {
    LoggerService.warning(
      'Failed to load config from assets, using default',
      'CONFIG',
    );
    config = _createDefaultConfig();
  }

  // Validate service role key
  if (config.serviceRoleKey == null || config.serviceRoleKey!.isEmpty) {
    LoggerService.warning(
      'Service role key not configured, using anon key only',
      'CONFIG',
    );
  } else {
    LoggerService.info('Service role key configured', 'CONFIG');
  }

  // Initialize Supabase (regular client)
  LoggerService.info('Initializing Supabase client', 'SUPABASE');
  await Supabase.initialize(url: config.supabaseUrl, anonKey: config.anonKey);
  LoggerService.info('Supabase client initialized successfully', 'SUPABASE');

  // Initialize Supabase Service Client (for RLS bypass)
  if (config.serviceRoleKey != null && config.serviceRoleKey!.isNotEmpty) {
    LoggerService.info(
      'Initializing Supabase Service Client',
      'SUPABASE_SERVICE',
    );
    try {
      await SupabaseServiceClient().initialize(config);
      LoggerService.info(
        'Supabase Service Client initialized successfully',
        'SUPABASE_SERVICE',
      );

      // Test service connection
      final connectionOk = await SupabaseServiceClient().testConnection();
      if (connectionOk) {
        LoggerService.info(
          'Service client connection test passed',
          'SUPABASE_SERVICE',
        );
      } else {
        LoggerService.warning(
          'Service client connection test failed',
          'SUPABASE_SERVICE',
        );
      }
    } catch (e) {
      LoggerService.error(
        'Failed to initialize Service Client',
        'SUPABASE_SERVICE',
        e,
      );
      LoggerService.warning(
        'Will continue with regular client only',
        'SUPABASE_SERVICE',
      );
    }
  }

  // Initialize DI
  LoggerService.info('Initializing dependency injection', 'DI');
  await di.init();
  LoggerService.info('Dependency injection initialized successfully', 'DI');

  LoggerService.info('App initialization completed successfully', 'MAIN');
}

AppConfig _createDefaultConfig() {
  return AppConfig(
    supabaseUrl: 'https://localhost.supabase.co',
    anonKey:
        'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvY2FsaG9zdCIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNjQxNzY5MjAwLCJleHAiOjE5NTczNDUyMDB9.default-anon-key',
    serviceRoleKey: null,
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
