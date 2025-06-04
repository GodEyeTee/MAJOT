import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';

/// Abstract network information interface
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get connectionStream;
  Future<NetworkQuality> get connectionQuality;
  Future<Map<String, dynamic>> get networkStats;
  void dispose();
}

/// Network connection quality enumeration
enum NetworkQuality { excellent, good, fair, poor, disconnected }

/// Network statistics data class
class NetworkStats {
  final bool isConnected;
  final NetworkQuality quality;
  final int latencyMs;
  final DateTime lastCheck;
  final int consecutiveFailures;
  final Duration uptime;

  const NetworkStats({
    required this.isConnected,
    required this.quality,
    required this.latencyMs,
    required this.lastCheck,
    this.consecutiveFailures = 0,
    this.uptime = Duration.zero,
  });

  Map<String, dynamic> toMap() {
    return {
      'isConnected': isConnected,
      'quality': quality.name,
      'latencyMs': latencyMs,
      'lastCheck': lastCheck.toIso8601String(),
      'consecutiveFailures': consecutiveFailures,
      'uptimeSeconds': uptime.inSeconds,
    };
  }
}

/// Enhanced network info implementation with monitoring and caching
class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;

  // State management
  bool _isConnected = false;
  NetworkQuality _currentQuality = NetworkQuality.disconnected;
  int _consecutiveFailures = 0;
  DateTime? _connectionStartTime;
  DateTime _lastCheck = DateTime.now();

  // Streaming and caching
  StreamController<bool>? _connectionController;
  Timer? _monitoringTimer;
  Timer? _qualityCheckTimer;

  // Performance optimization
  static const Duration _cacheValidity = Duration(seconds: 5);
  static const Duration _monitoringInterval = Duration(seconds: 30);
  static const Duration _qualityCheckInterval = Duration(seconds: 2);

  NetworkInfoImpl(this.connectionChecker) {
    _initializeMonitoring();
    if (!kReleaseMode) {
      debugPrint('🌐 NetworkInfo initialized with enhanced monitoring');
    }
  }

  /// Initialize network monitoring with performance optimization
  void _initializeMonitoring() {
    _connectionController = StreamController<bool>.broadcast();

    // Start initial connection check
    _performConnectionCheck();

    // Set up periodic monitoring
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) {
      _performConnectionCheck();
    });

    // Set up quality assessment
    _qualityCheckTimer = Timer.periodic(_qualityCheckInterval, (_) {
      _assessConnectionQuality();
    });
  }

  @override
  Future<bool> get isConnected async {
    // Use cached result if recent
    if (_isCacheValid() &&
        _lastCheck.isAfter(DateTime.now().subtract(_cacheValidity))) {
      return _isConnected;
    }

    // Perform fresh check
    return await _performConnectionCheck();
  }

  @override
  Stream<bool> get connectionStream {
    return _connectionController?.stream ?? Stream.value(_isConnected);
  }

  @override
  Future<NetworkQuality> get connectionQuality async {
    await _assessConnectionQuality();
    return _currentQuality;
  }

  @override
  Future<Map<String, dynamic>> get networkStats async {
    final stats = NetworkStats(
      isConnected: _isConnected,
      quality: _currentQuality,
      latencyMs: await _measureLatency(),
      lastCheck: _lastCheck,
      consecutiveFailures: _consecutiveFailures,
      uptime: _getUptime(),
    );

    return stats.toMap();
  }

  /// Perform connection check with error handling
  Future<bool> _performConnectionCheck() async {
    try {
      final wasConnected = _isConnected;

      // Check connection with timeout
      _isConnected = await connectionChecker.hasConnection;
      _lastCheck = DateTime.now();

      // Handle connection state changes
      if (_isConnected != wasConnected) {
        await _handleConnectionChange(_isConnected);
      }

      // Reset failure counter on success
      if (_isConnected) {
        _consecutiveFailures = 0;
        _connectionStartTime ??= DateTime.now();
      } else {
        _consecutiveFailures++;
        _connectionStartTime = null;
      }

      // Notify listeners
      _connectionController?.add(_isConnected);

      if (!kReleaseMode) {
        debugPrint(
          '🌐 Connection check: ${_isConnected ? "connected" : "disconnected"}',
        );
      }

      return _isConnected;
    } catch (e) {
      _consecutiveFailures++;
      _isConnected = false;
      _connectionStartTime = null;

      if (!kReleaseMode) {
        debugPrint('❌ Connection check failed: $e');
      }

      _connectionController?.add(false);
      return false;
    }
  }

  /// Assess connection quality based on various metrics
  Future<void> _assessConnectionQuality() async {
    if (!_isConnected) {
      _currentQuality = NetworkQuality.disconnected;
      return;
    }

    try {
      final latency = await _measureLatency();

      // Determine quality based on latency and stability
      if (latency < 100 && _consecutiveFailures == 0) {
        _currentQuality = NetworkQuality.excellent;
      } else if (latency < 300 && _consecutiveFailures < 2) {
        _currentQuality = NetworkQuality.good;
      } else if (latency < 1000 && _consecutiveFailures < 5) {
        _currentQuality = NetworkQuality.fair;
      } else {
        _currentQuality = NetworkQuality.poor;
      }

      if (!kReleaseMode) {
        debugPrint(
          '🌐 Connection quality: ${_currentQuality.name} (${latency}ms)',
        );
      }
    } catch (e) {
      _currentQuality = NetworkQuality.poor;
      if (!kReleaseMode) {
        debugPrint('❌ Quality assessment failed: $e');
      }
    }
  }

  /// Measure network latency for quality assessment
  Future<int> _measureLatency() async {
    try {
      final stopwatch = Stopwatch()..start();

      // Use the same hosts as InternetConnectionChecker
      await connectionChecker.hasConnection;

      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (e) {
      // Return high latency on error
      return 5000;
    }
  }

  /// Handle connection state changes with logging
  Future<void> _handleConnectionChange(bool isConnected) async {
    if (!kReleaseMode) {
      if (isConnected) {
        debugPrint('✅ Network connection restored');
      } else {
        debugPrint('❌ Network connection lost');
      }
    }

    // Update quality immediately on connection change
    if (isConnected) {
      await _assessConnectionQuality();
    } else {
      _currentQuality = NetworkQuality.disconnected;
    }
  }

  /// Check if cached result is still valid
  bool _isCacheValid() {
    return DateTime.now().difference(_lastCheck) < _cacheValidity;
  }

  /// Get connection uptime
  Duration _getUptime() {
    final startTime = _connectionStartTime;
    if (startTime == null || !_isConnected) {
      return Duration.zero;
    }
    return DateTime.now().difference(startTime);
  }

  /// Get detailed network information for debugging
  Map<String, dynamic> getDetailedNetworkInfo() {
    if (kReleaseMode) {
      return {'status': 'production_mode'};
    }

    return {
      'connection_status': _isConnected,
      'quality': _currentQuality.name,
      'consecutive_failures': _consecutiveFailures,
      'last_check': _lastCheck.toIso8601String(),
      'uptime_seconds': _getUptime().inSeconds,
      'cache_valid': _isCacheValid(),
      'monitoring_active': _monitoringTimer?.isActive ?? false,
      'quality_monitoring_active': _qualityCheckTimer?.isActive ?? false,
      'connection_checker_config': {
        'check_timeout': connectionChecker.checkTimeout.inSeconds,
        'check_interval': connectionChecker.checkInterval.inSeconds,
      },
    };
  }

  /// Get connection health score (0-100)
  int getConnectionHealthScore() {
    if (!_isConnected) return 0;

    int score = 50; // Base score for being connected

    // Quality bonus
    switch (_currentQuality) {
      case NetworkQuality.excellent:
        score += 40;
        break;
      case NetworkQuality.good:
        score += 30;
        break;
      case NetworkQuality.fair:
        score += 20;
        break;
      case NetworkQuality.poor:
        score += 10;
        break;
      case NetworkQuality.disconnected:
        return 0;
    }

    // Stability bonus (fewer failures = higher score)
    if (_consecutiveFailures == 0) {
      score += 10;
    } else if (_consecutiveFailures < 3) {
      score += 5;
    } else {
      score -= 10;
    }

    // Uptime bonus
    final uptime = _getUptime();
    if (uptime.inMinutes > 30) {
      score += 5;
    }

    return score.clamp(0, 100);
  }

  /// Force refresh connection status
  Future<bool> forceRefresh() async {
    if (!kReleaseMode) {
      debugPrint('🔄 Forcing network status refresh...');
    }

    return await _performConnectionCheck();
  }

  /// Wait for connection to be available
  Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
    Duration checkInterval = const Duration(seconds: 2),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      if (await isConnected) {
        return true;
      }

      await Future.delayed(checkInterval);
    }

    return false;
  }

  /// Test connection to specific host
  Future<bool> testConnection(String host, {int port = 80}) async {
    try {
      final addresses = await InternetAddress.lookup(host);
      if (addresses.isNotEmpty) {
        final socket = await Socket.connect(addresses.first, port);
        socket.destroy();
        return true;
      }
    } catch (e) {
      if (!kReleaseMode) {
        debugPrint('❌ Connection test to $host:$port failed: $e');
      }
    }
    return false;
  }

  @override
  void dispose() {
    try {
      _monitoringTimer?.cancel();
      _qualityCheckTimer?.cancel();
      _connectionController?.close();

      if (!kReleaseMode) {
        debugPrint('🧹 NetworkInfo disposed');
      }
    } catch (e) {
      if (!kReleaseMode) {
        debugPrint('⚠️ NetworkInfo disposal error: $e');
      }
    }
  }
}

/// Network info provider for dependency injection
class NetworkInfoProvider {
  static NetworkInfo? _instance;

  static NetworkInfo getInstance(InternetConnectionChecker connectionChecker) {
    return _instance ??= NetworkInfoImpl(connectionChecker);
  }

  static void dispose() {
    _instance?.dispose();
    _instance = null;
  }
}

/// Network monitoring service for global access
class NetworkMonitoringService {
  static final NetworkMonitoringService _instance =
      NetworkMonitoringService._internal();
  factory NetworkMonitoringService() => _instance;
  NetworkMonitoringService._internal();

  NetworkInfo? _networkInfo;
  final List<Function(bool)> _listeners = [];
  StreamSubscription? _subscription;

  void initialize(NetworkInfo networkInfo) {
    _networkInfo = networkInfo;
    _subscription = networkInfo.connectionStream.listen(_notifyListeners);
  }

  void addListener(Function(bool) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(bool) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(bool isConnected) {
    for (final listener in _listeners) {
      try {
        listener(isConnected);
      } catch (e) {
        if (!kReleaseMode) {
          debugPrint('❌ Network listener error: $e');
        }
      }
    }
  }

  Future<bool> get isConnected async {
    return await _networkInfo?.isConnected ?? false;
  }

  Future<NetworkQuality> get quality async {
    return await _networkInfo?.connectionQuality ?? NetworkQuality.disconnected;
  }

  void dispose() {
    _subscription?.cancel();
    _listeners.clear();
    _networkInfo?.dispose();
    _networkInfo = null;
  }
}
