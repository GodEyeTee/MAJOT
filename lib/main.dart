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

  // Load configuration
  final config = await AppConfig.fromAsset();

  // Initialize Supabase
  await Supabase.initialize(url: config.supabaseUrl, anonKey: config.anonKey);

  // Initialize dependency injection
  await di.init();

  runApp(const App());
}
