import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/app_config_loader.dart';
import 'core/di/injection_container.dart' as di;
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  try {
    // Load configuration
    final config = await AppConfig.fromAsset();
    print('Supabase URL: ${config.supabaseUrl}');

    // ตรวจสอบความถูกต้องของ URL และ anonKey
    if (config.supabaseUrl.isEmpty ||
        !config.supabaseUrl.startsWith('https://')) {
      print('Warning: Invalid Supabase URL: ${config.supabaseUrl}');
    }

    if (config.anonKey.isEmpty) {
      print('Warning: Empty Supabase anon key');
    }

    // Initialize Supabase
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.anonKey,
      debug: true, // เพิ่ม debug mode
    );

    print('Supabase initialized successfully');
  } catch (e) {
    print('Failed to initialize Supabase: $e');
    // แต่ยังดำเนินการต่อไป เพราะเราต้องการให้ Firebase ทำงานได้แม้ว่า Supabase จะมีปัญหา
  }

  // Initialize dependency injection
  await di.init();

  runApp(const App());
}
