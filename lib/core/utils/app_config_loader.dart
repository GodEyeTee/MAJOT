import 'dart:convert';
import 'package:flutter/services.dart';

class AppConfig {
  final String supabaseUrl;
  final String anonKey;

  AppConfig({required this.supabaseUrl, required this.anonKey});

  static Future<AppConfig> fromAsset([
    String path = 'assets/config/app_config.json',
  ]) async {
    try {
      final String configString = await rootBundle.loadString(path);
      final Map<String, dynamic> config = json.decode(configString);

      // ตรวจสอบว่ามี URL ใน config หรือไม่
      final url = config['supabaseUrl'] ?? '';
      if (url.isEmpty) {
        throw Exception('Supabase URL is empty or not found in config');
      }

      // ตรวจสอบว่า URL มีรูปแบบที่ถูกต้องหรือไม่
      if (!url.startsWith('https://')) {
        throw Exception('Supabase URL must start with https://');
      }

      return AppConfig(supabaseUrl: url, anonKey: config['anonKey'] ?? '');
    } catch (e) {
      throw Exception('Failed to load app configuration: $e');
    }
  }
}
