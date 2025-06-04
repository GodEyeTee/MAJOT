class AppConstants {
  // API related constants
  static const int apiConnectionTimeout = 15000; // milliseconds
  static const int apiReceiveTimeout = 15000; // milliseconds

  // Storage related constants
  static const String userCacheKey = 'CACHED_USER';
  static const String tokenCacheKey = 'CACHED_TOKEN';
  static const String themeModeKey = 'THEME_MODE';

  // Feature flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;

  // Routes
  static const String homeRoute = '/';
  static const String loginRoute = '/login';
  static const String walletRoute = '/wallet';
  static const String analyticsRoute = '/analytics';
  static const String settingsRoute = '/settings';

  // Cache durations
  static const Duration userCacheValidity = Duration(minutes: 5);
  static const Duration networkCacheValidity = Duration(seconds: 5);
  static const Duration tokenRefreshThreshold = Duration(minutes: 55);

  // Retry configurations
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration operationTimeout = Duration(seconds: 10);

  // Prevent instantiation
  const AppConstants._();
}
