import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/app_config_loader.dart';
import 'core/di/injection_container.dart' as di;
import 'app.dart';

/// Main entry point with comprehensive error handling and security
Future<void> main() async {
  // Ensure Flutter is properly initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Production optimizations
  if (kReleaseMode) {
    // Disable debug prints in production
    debugPrint = (String? message, {int? wrapWidth}) {};

    // Set preferred orientations for better UX
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Initialize app with error boundary
  await _initializeAppWithErrorHandling();
}

/// Initialize app with comprehensive error handling
Future<void> _initializeAppWithErrorHandling() async {
  try {
    print('🚀 Starting app initialization...');

    // Initialize core services
    await _initializeCoreServices();

    // Initialize external services
    await _initializeExternalServices();

    // Initialize dependency injection
    await _initializeDependencyInjection();

    print('✅ App initialization completed successfully');

    // Run the app
    runApp(const SecureApp());
  } catch (e, stackTrace) {
    print('❌ Critical app initialization error: $e');

    if (!kReleaseMode) {
      print('Stack trace: $stackTrace');
    }

    // Run fallback app
    runApp(_buildErrorApp(e.toString()));
  }
}

/// Initialize core Flutter services
Future<void> _initializeCoreServices() async {
  try {
    print('⚙️ Initializing core services...');

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Enable edge-to-edge
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    print('✅ Core services initialized');
  } catch (e) {
    print('⚠️ Core services initialization warning: $e');
    // Don't throw - these are nice-to-have features
  }
}

/// Initialize external services (Firebase, Supabase)
Future<void> _initializeExternalServices() async {
  // Initialize Firebase first
  await _initializeFirebase();

  // Initialize Supabase
  await _initializeSupabase();
}

/// Initialize Firebase with error handling
Future<void> _initializeFirebase() async {
  try {
    print('🔥 Initializing Firebase...');

    await Firebase.initializeApp(
      options: kIsWeb ? null : null, // Add your Firebase options here if needed
    );

    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');

    if (kReleaseMode) {
      throw Exception('Critical service initialization failed');
    }
    rethrow;
  }
}

/// Initialize Supabase with enhanced error handling
Future<void> _initializeSupabase() async {
  try {
    print('🗄️ Initializing Supabase...');

    // Load configuration with validation
    final config = await _loadAndValidateConfig();

    // Initialize Supabase with configuration
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.anonKey,
      debug: kDebugMode,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );

    print('✅ Supabase initialized successfully');

    // Validate connection
    await _validateSupabaseConnection();
  } catch (e) {
    print('⚠️ Supabase initialization failed: $e');
    print('📱 App will continue with limited functionality');

    // Don't throw - app can work without Supabase
    // Just log the error and continue
  }
}

/// Load and validate app configuration
Future<AppConfig> _loadAndValidateConfig() async {
  try {
    final config = await AppConfig.fromAsset();

    // Enhanced validation
    if (config.supabaseUrl.isEmpty) {
      throw Exception('Supabase URL is required');
    }

    if (!config.supabaseUrl.startsWith('https://')) {
      throw Exception('Supabase URL must use HTTPS');
    }

    if (config.anonKey.isEmpty) {
      throw Exception('Supabase anonymous key is required');
    }

    // Validate URL format
    final uri = Uri.tryParse(config.supabaseUrl);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw Exception('Invalid Supabase URL format');
    }

    if (!kReleaseMode) {
      print('📋 Configuration loaded:');
      print('   Supabase URL: ${_maskUrl(config.supabaseUrl)}');
      print('   Anon Key: ${_maskKey(config.anonKey)}');
    }

    return config;
  } catch (e) {
    print('❌ Configuration loading failed: $e');
    rethrow;
  }
}

/// Validate Supabase connection
Future<void> _validateSupabaseConnection() async {
  try {
    final client = Supabase.instance.client;

    // Test connection with timeout
    await client
        .from('users')
        .select('id')
        .limit(1)
        .timeout(const Duration(seconds: 5));

    print('✅ Supabase connection validated');
  } catch (e) {
    print('⚠️ Supabase connection validation failed: $e');
    // Don't throw - connection issues are common and shouldn't prevent startup
  }
}

/// Initialize dependency injection
Future<void> _initializeDependencyInjection() async {
  try {
    print('💉 Initializing dependency injection...');

    await di.init();

    print('✅ Dependency injection initialized');

    // Validate critical dependencies
    await _validateCriticalDependencies();
  } catch (e) {
    print('❌ Dependency injection initialization failed: $e');

    if (kReleaseMode) {
      throw Exception('Critical app services initialization failed');
    }
    rethrow;
  }
}

/// Validate critical dependencies
Future<void> _validateCriticalDependencies() async {
  try {
    final healthStatus = di.getDependencyHealthStatus();

    if (!kReleaseMode) {
      print('🔍 Dependency health check:');
      print('   Status: ${healthStatus['status'] ?? 'unknown'}');

      if (healthStatus.containsKey('performance')) {
        final performance = healthStatus['performance'] as Map<String, dynamic>;
        print('   Health Score: ${performance['health_score']}');
        print('   Registration Rate: ${performance['registration_rate']}');
      }
    }

    print('✅ Critical dependencies validated');
  } catch (e) {
    print('⚠️ Dependency validation warning: $e');
    // Don't throw - validation failures shouldn't prevent app startup
  }
}

/// Build error app for critical failures
Widget _buildErrorApp(String error) {
  return MaterialApp(
    title: 'App Error',
    home: Scaffold(
      backgroundColor: Colors.red.shade50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
                const SizedBox(height: 24),
                Text(
                  'App Initialization Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please restart the app or contact support if the problem persists.',
                  style: TextStyle(fontSize: 16, color: Colors.red.shade600),
                  textAlign: TextAlign.center,
                ),
                if (!kReleaseMode) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Debug Information:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Restart app
                    SystemNavigator.pop();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart App'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Secure main app wrapper
class SecureApp extends StatelessWidget {
  const SecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}

/// Utility functions for security
String _maskUrl(String url) {
  if (kReleaseMode) return '[MASKED]';

  try {
    final uri = Uri.parse(url);
    final host = uri.host;
    if (host.length > 10) {
      return '${host.substring(0, 5)}***${host.substring(host.length - 3)}';
    }
    return host;
  } catch (e) {
    return '[INVALID URL]';
  }
}

String _maskKey(String key) {
  if (kReleaseMode) return '[MASKED]';

  if (key.length > 8) {
    return '${key.substring(0, 4)}***${key.substring(key.length - 4)}';
  }
  return '[SHORT KEY]';
}

/// Global error handler
void _setupGlobalErrorHandling() {
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kReleaseMode) {
      // In production, log to crash reporting service
      // FirebaseCrashlytics.instance.recordFlutterError(details);
    } else {
      // In development, print to console
      FlutterError.presentError(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kReleaseMode) {
      // In production, log to crash reporting service
      // FirebaseCrashlytics.instance.recordError(error, stack);
    } else {
      // In development, print to console
      print('Global error: $error\n$stack');
    }
    return true;
  };
}
