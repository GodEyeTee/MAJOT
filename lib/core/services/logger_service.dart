import 'package:flutter/foundation.dart';

enum LogLevel { info, warning, error, debug }

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  static bool get isDebugMode => !kReleaseMode;

  static void info(String message, [String? tag]) {
    _log(LogLevel.info, message, tag);
  }

  static void warning(String message, [String? tag]) {
    _log(LogLevel.warning, message, tag);
  }

  static void error(String message, [String? tag, dynamic error]) {
    _log(LogLevel.error, message, tag);
    if (error != null && isDebugMode) {
      _log(LogLevel.error, 'Error details: $error', tag);
    }
  }

  static void debug(String message, [String? tag]) {
    if (isDebugMode) {
      _log(LogLevel.debug, message, tag);
    }
  }

  static void _log(LogLevel level, String message, String? tag) {
    if (!isDebugMode && level == LogLevel.debug) return;

    final timestamp = DateTime.now().toIso8601String();
    final prefix = _getLevelPrefix(level);
    final tagStr = tag != null ? '[$tag] ' : '';

    if (kDebugMode) {
      print('$timestamp $prefix $tagStr$message');
    }
  }

  static String _getLevelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return 'ℹ️ ';
      case LogLevel.warning:
        return '⚠️ ';
      case LogLevel.error:
        return '❌';
      case LogLevel.debug:
        return '🔍';
    }
  }
}
