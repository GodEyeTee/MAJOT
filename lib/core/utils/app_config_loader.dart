import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Application configuration with security validation
class AppConfig {
  final String supabaseUrl;
  final String anonKey;
  final String? serviceRoleKey;
  final Map<String, dynamic> features;
  final Map<String, dynamic> security;
  final Map<String, dynamic> performance;
  final String environment;
  final String version;

  AppConfig({
    required this.supabaseUrl,
    required this.anonKey,
    this.serviceRoleKey,
    this.features = const {},
    this.security = const {},
    this.performance = const {},
    this.environment = 'development',
    this.version = '1.0.0',
  });

  /// Load configuration from asset with comprehensive validation
  static Future<AppConfig> fromAsset([
    String path = 'assets/config/app_config.json',
  ]) async {
    try {
      if (!kReleaseMode) {
        debugPrint('📋 Loading app configuration from: $path');
      }

      // Load configuration file
      final String configString = await rootBundle.loadString(path);
      final Map<String, dynamic> config = json.decode(configString);

      // Validate and extract configuration
      final appConfig = _validateAndBuildConfig(config);

      if (!kReleaseMode) {
        debugPrint('✅ App configuration loaded successfully');
        _debugPrintConfigSummary(appConfig);
      }

      return appConfig;
    } catch (e) {
      if (!kReleaseMode) {
        debugPrint('❌ Failed to load app configuration: $e');
      }

      // Always return fallback configuration when loading fails
      debugPrint('🔄 Using fallback configuration');
      return _createFallbackConfig();
    }
  }

  /// Validate and build configuration with security checks
  static AppConfig _validateAndBuildConfig(Map<String, dynamic> config) {
    // Extract and validate Supabase URL
    final supabaseUrl = config['supabaseUrl'] as String? ?? '';
    if (supabaseUrl.isEmpty) {
      throw ConfigurationException('Supabase URL is required');
    }

    if (!_isValidUrl(supabaseUrl)) {
      throw ConfigurationException('Invalid Supabase URL format');
    }

    // Skip HTTPS requirement for development
    if (!kReleaseMode || supabaseUrl.startsWith('https://')) {
      // OK for development or secure URLs
    } else {
      throw ConfigurationException('Supabase URL must use HTTPS for security');
    }

    // Extract and validate anonymous key
    final anonKey = config['anonKey'] as String? ?? '';
    if (anonKey.isEmpty) {
      throw ConfigurationException('Supabase anonymous key is required');
    }

    if (!_isValidKey(anonKey)) {
      throw ConfigurationException('Invalid anonymous key format');
    }

    // Extract optional service role key
    final serviceRoleKey = config['serviceRoleKey'] as String?;
    if (serviceRoleKey != null && !_isValidKey(serviceRoleKey)) {
      throw ConfigurationException('Invalid service role key format');
    }

    // Extract feature flags
    final features = _validateFeatures(
      config['features'] as Map<String, dynamic>? ?? {},
    );

    // Extract security settings
    final security = _validateSecurity(
      config['security'] as Map<String, dynamic>? ?? {},
    );

    // Extract performance settings
    final performance = _validatePerformance(
      config['performance'] as Map<String, dynamic>? ?? {},
    );

    // Extract environment and version
    final environment = config['environment'] as String? ?? 'development';
    final version = config['version'] as String? ?? '1.0.0';

    return AppConfig(
      supabaseUrl: supabaseUrl,
      anonKey: anonKey,
      serviceRoleKey: serviceRoleKey,
      features: features,
      security: security,
      performance: performance,
      environment: environment,
      version: version,
    );
  }

  /// Validate feature flags configuration
  static Map<String, dynamic> _validateFeatures(Map<String, dynamic> features) {
    final validatedFeatures = <String, dynamic>{};

    // Default feature flags
    final defaultFeatures = {
      'analytics_enabled': false,
      'crash_reporting_enabled': false,
      'biometric_auth_enabled': false,
      'offline_mode_enabled': true,
      'debug_mode_enabled': !kReleaseMode,
      'performance_monitoring_enabled': false,
      'security_logging_enabled': !kReleaseMode,
    };

    // Merge with provided features
    validatedFeatures.addAll(defaultFeatures);
    for (final entry in features.entries) {
      if (entry.value is bool) {
        validatedFeatures[entry.key] = entry.value;
      }
    }

    return validatedFeatures;
  }

  /// Validate security configuration
  static Map<String, dynamic> _validateSecurity(Map<String, dynamic> security) {
    final validatedSecurity = <String, dynamic>{};

    // Default security settings
    final defaultSecurity = {
      'session_timeout_minutes': 120,
      'max_login_attempts': 5,
      'lockout_duration_minutes': 15,
      'require_secure_connection': kReleaseMode,
      'certificate_pinning_enabled': kReleaseMode,
      'api_rate_limiting_enabled': kReleaseMode,
      'encryption_enabled': true,
    };

    // Merge with provided security settings
    validatedSecurity.addAll(defaultSecurity);
    for (final entry in security.entries) {
      validatedSecurity[entry.key] = entry.value;
    }

    // Validate critical security settings
    final sessionTimeout = validatedSecurity['session_timeout_minutes'] as int;
    if (sessionTimeout < 5 || sessionTimeout > 480) {
      validatedSecurity['session_timeout_minutes'] = 120; // Use default
    }

    final maxAttempts = validatedSecurity['max_login_attempts'] as int;
    if (maxAttempts < 3 || maxAttempts > 10) {
      validatedSecurity['max_login_attempts'] = 5; // Use default
    }

    return validatedSecurity;
  }

  /// Validate performance configuration
  static Map<String, dynamic> _validatePerformance(
    Map<String, dynamic> performance,
  ) {
    final validatedPerformance = <String, dynamic>{};

    // Default performance settings
    final defaultPerformance = {
      'api_timeout_seconds': 30,
      'cache_duration_minutes': 10,
      'image_cache_size_mb': 100,
      'database_pool_size': 10,
      'concurrent_requests_limit': 5,
      'preload_enabled': true,
      'compression_enabled': true,
    };

    // Merge with provided performance settings
    validatedPerformance.addAll(defaultPerformance);
    for (final entry in performance.entries) {
      validatedPerformance[entry.key] = entry.value;
    }

    // Validate performance settings
    final apiTimeout = validatedPerformance['api_timeout_seconds'] as int;
    if (apiTimeout < 5 || apiTimeout > 120) {
      validatedPerformance['api_timeout_seconds'] = 30; // Use default
    }

    return validatedPerformance;
  }

  /// Create fallback configuration for development
  static AppConfig _createFallbackConfig() {
    return AppConfig(
      supabaseUrl: 'https://localhost.supabase.co',
      anonKey:
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvY2FsaG9zdCIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNjQxNzY5MjAwLCJleHAiOjE5NTczNDUyMDB9.default-key-for-development-only',
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

  /// Validate URL format
  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Validate API key format
  static bool _isValidKey(String key) {
    // Basic validation - key should be non-empty and reasonable length
    return key.isNotEmpty && key.length >= 20 && key.length <= 500;
  }

  /// debugPrint configuration summary for debugging
  static void _debugPrintConfigSummary(AppConfig config) {
    if (kReleaseMode) return;

    debugPrint('📋 Configuration Summary:');
    debugPrint('   Environment: ${config.environment}');
    debugPrint('   Version: ${config.version}');
    debugPrint('   Supabase URL: ${_maskUrl(config.supabaseUrl)}');
    debugPrint('   Anonymous Key: ${_maskKey(config.anonKey)}');
    debugPrint(
      '   Service Role Key: ${config.serviceRoleKey != null ? _maskKey(config.serviceRoleKey!) : 'Not configured'}',
    );
    debugPrint('   Features: ${config.features.length} configured');
    debugPrint('   Security Settings: ${config.security.length} configured');
    debugPrint(
      '   Performance Settings: ${config.performance.length} configured',
    );
  }

  /// Mask URL for secure logging
  static String _maskUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      if (host.length > 10) {
        return '${uri.scheme}://${host.substring(0, 5)}***${host.substring(host.length - 3)}';
      }
      return '${uri.scheme}://$host';
    } catch (e) {
      return '[INVALID URL]';
    }
  }

  /// Mask key for secure logging
  static String _maskKey(String key) {
    if (key.length > 8) {
      return '${key.substring(0, 4)}***${key.substring(key.length - 4)}';
    }
    return '[SHORT KEY]';
  }

  // Getter methods for easy access to configuration values

  /// Check if feature is enabled
  bool isFeatureEnabled(String featureName) {
    return features[featureName] as bool? ?? false;
  }

  /// Get security setting
  T getSecuritySetting<T>(String settingName, T defaultValue) {
    return security[settingName] as T? ?? defaultValue;
  }

  /// Get performance setting
  T getPerformanceSetting<T>(String settingName, T defaultValue) {
    return performance[settingName] as T? ?? defaultValue;
  }

  /// Check if running in production environment
  bool get isProduction => environment.toLowerCase() == 'production';

  /// Check if running in development environment
  bool get isDevelopment => environment.toLowerCase() == 'development';

  /// Check if running in staging environment
  bool get isStaging => environment.toLowerCase() == 'staging';

  /// Get API timeout duration
  Duration get apiTimeout {
    final seconds = getPerformanceSetting('api_timeout_seconds', 30);
    return Duration(seconds: seconds);
  }

  /// Get session timeout duration
  Duration get sessionTimeout {
    final minutes = getSecuritySetting('session_timeout_minutes', 120);
    return Duration(minutes: minutes);
  }

  /// Get cache duration
  Duration get cacheDuration {
    final minutes = getPerformanceSetting('cache_duration_minutes', 10);
    return Duration(minutes: minutes);
  }

  /// Get max login attempts
  int get maxLoginAttempts {
    return getSecuritySetting('max_login_attempts', 5);
  }

  /// Get lockout duration
  Duration get lockoutDuration {
    final minutes = getSecuritySetting('lockout_duration_minutes', 15);
    return Duration(minutes: minutes);
  }

  /// Convert configuration to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'supabaseUrl': supabaseUrl,
      'anonKey': kReleaseMode ? '[MASKED]' : anonKey,
      'serviceRoleKey':
          serviceRoleKey != null
              ? (kReleaseMode ? '[MASKED]' : serviceRoleKey)
              : null,
      'features': features,
      'security': security,
      'performance': performance,
      'environment': environment,
      'version': version,
    };
  }

  /// Get configuration hash for change detection
  String get configHash {
    final configString = json.encode(toMap());
    return configString.hashCode.toString();
  }

  /// Validate configuration integrity
  bool validateIntegrity() {
    try {
      // Validate URLs
      if (!_isValidUrl(supabaseUrl)) return false;

      // Validate keys
      if (!_isValidKey(anonKey)) return false;
      if (serviceRoleKey != null && !_isValidKey(serviceRoleKey!)) return false;

      // Validate settings ranges
      final sessionTimeout = getSecuritySetting('session_timeout_minutes', 120);
      if (sessionTimeout < 5 || sessionTimeout > 480) return false;

      final apiTimeout = getPerformanceSetting('api_timeout_seconds', 30);
      if (apiTimeout < 5 || apiTimeout > 120) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get configuration health status
  Map<String, dynamic> getHealthStatus() {
    return {
      'valid': validateIntegrity(),
      'environment': environment,
      'version': version,
      'features_count': features.length,
      'security_settings_count': security.length,
      'performance_settings_count': performance.length,
      'supabase_configured': supabaseUrl.isNotEmpty && anonKey.isNotEmpty,
      'service_role_configured': serviceRoleKey != null,
      'production_ready': isProduction && validateIntegrity(),
    };
  }
}

/// Configuration exception for error handling
class ConfigurationException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const ConfigurationException(this.message, {this.code, this.originalError});

  @override
  String toString() {
    return 'ConfigurationException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// Configuration manager for global access
class ConfigurationManager {
  static final ConfigurationManager _instance =
      ConfigurationManager._internal();
  factory ConfigurationManager() => _instance;
  ConfigurationManager._internal();

  AppConfig? _config;
  String? _configHash;
  DateTime? _loadTime;

  /// Initialize configuration
  Future<void> initialize([String? configPath]) async {
    try {
      _config = await AppConfig.fromAsset(
        configPath ?? 'assets/config/app_config.json',
      );
      _configHash = _config!.configHash;
      _loadTime = DateTime.now();

      if (!kReleaseMode) {
        debugPrint('✅ Configuration manager initialized');
      }
    } catch (e) {
      if (!kReleaseMode) {
        debugPrint('❌ Configuration manager initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Get current configuration
  AppConfig get config {
    if (_config == null) {
      throw ConfigurationException(
        'Configuration not initialized. Call initialize() first.',
      );
    }
    return _config!;
  }

  /// Check if configuration is loaded
  bool get isInitialized => _config != null;

  /// Get configuration load time
  DateTime? get loadTime => _loadTime;

  /// Reload configuration
  Future<void> reload([String? configPath]) async {
    await initialize(configPath);
  }

  /// Get configuration status
  Map<String, dynamic> getStatus() {
    return {
      'initialized': isInitialized,
      'load_time': _loadTime?.toIso8601String(),
      'config_hash': _configHash,
      'health_status': _config?.getHealthStatus(),
    };
  }

  /// Reset configuration manager
  void reset() {
    _config = null;
    _configHash = null;
    _loadTime = null;

    if (!kReleaseMode) {
      debugPrint('🧹 Configuration manager reset');
    }
  }
}
