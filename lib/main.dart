import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/app_config_loader.dart';
import 'core/di/injection_container.dart' as di;
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initializeApp();
    runApp(const App());
  } catch (e) {
    print('❌ App initialization failed: $e');
    runApp(_buildErrorApp(e.toString()));
  }
}

Future<void> _initializeApp() async {
  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase
  final config = await AppConfig.fromAsset();
  await Supabase.initialize(url: config.supabaseUrl, anonKey: config.anonKey);

  // Initialize DI
  await di.init();
}

Widget _buildErrorApp(String error) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Initialization Failed', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(error),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => SystemNavigator.pop(),
              child: const Text('Restart App'),
            ),
          ],
        ),
      ),
    ),
  );
}
