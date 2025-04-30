import 'dart:convert';
import 'package:flutter/services.dart';

class AppConfig {
  final String supabaseUrl;
  final String anonKey;

  AppConfig({required this.supabaseUrl, required this.anonKey});

  static Future<AppConfig> fromAsset() async {
    try {
      final String configString = await rootBundle.loadString(
        'assets/config/app_config.json',
      );
      final Map<String, dynamic> config = json.decode(configString);

      return AppConfig(
        supabaseUrl: config['supabaseUrl'] ?? '',
        anonKey: config['anonKey'] ?? '',
      );
    } catch (e) {
      throw Exception('Failed to load app configuration: $e');
    }
  }
}
