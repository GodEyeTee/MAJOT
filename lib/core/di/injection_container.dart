import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

// Core
import '../network/network_info.dart';

// Auth feature
import '../../features/auth/data/datasources/firebase_auth_data_source.dart';
import '../../features/auth/data/datasources/supabase_user_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/is_authenticated.dart';
import '../../features/auth/domain/usecases/sign_in_with_google.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Services
import '../../services/rbac/role_manager.dart';
import '../../services/rbac/rbac_service.dart';

final sl = GetIt.instance;

/// Production-grade Dependency Injection Container
/// Implements security validations and performance monitoring
Future<void> init() async {
  try {
    print('🔄 Initializing Secure DI Container...');
    final stopwatch = Stopwatch()..start();

    // Security: Validate critical dependencies first
    await _validateCriticalDependencies();

    // Register in dependency order for optimal performance
    await _registerExternalDependencies();
    await _registerCoreServices();
    await _registerAuthFeature();

    stopwatch.stop();

    // Performance monitoring
    final initTime = stopwatch.elapsedMilliseconds;
    if (initTime > 5000) {
      print('⚠️ DI initialization took ${initTime}ms - consider optimization');
    }

    // Security: Validate all critical registrations
    await _validateRegistrations();

    print('✅ Secure DI Container initialized in ${initTime}ms');

    // Production: Clear sensitive initialization data
    if (const bool.fromEnvironment('dart.vm.product')) {
      await _clearSensitiveData();
    }
  } catch (e, stackTrace) {
    print('❌ Critical DI initialization error: $e');
    print('Stack trace: $stackTrace');

    // Security: Don't expose internal errors in production
    if (const bool.fromEnvironment('dart.vm.product')) {
      throw Exception('Application initialization failed');
    }
    rethrow;
  }
}

/// Security: Validate critical external dependencies
Future<void> _validateCriticalDependencies() async {
  // Validate Firebase
  try {
    await FirebaseAuth.instance.authStateChanges().first.timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );
  } catch (e) {
    throw Exception(
      'Firebase validation failed: Critical security component unavailable',
    );
  }

  // Validate Supabase - Fixed: Use proper SupabaseClient validation
  try {
    final client = Supabase.instance.client;

    // Security: Test actual connection instead of checking properties
    await client
        .from('users')
        .select('id')
        .limit(1)
        .timeout(const Duration(seconds: 5));

    print('✅ Supabase connection validated');
  } catch (e) {
    // Warning instead of throwing - app can work offline
    print('⚠️ Supabase validation warning: $e - App will work in offline mode');
  }
}

/// Register external dependencies with security configurations
Future<void> _registerExternalDependencies() async {
  // Firebase - Production configuration
  sl.registerLazySingleton(() => FirebaseAuth.instance);

  // Google Sign-In - Secure configuration
  sl.registerLazySingleton(
    () => GoogleSignIn(
      scopes: ['email', 'profile'], // Minimal required scopes
      hostedDomain: null, // Allow all domains unless specifically restricted
    ),
  );

  // Supabase - Production client
  sl.registerLazySingleton(() => Supabase.instance.client);

  // Network - Enhanced monitoring
  sl.registerLazySingleton(
    () => InternetConnectionChecker.createInstance(
      checkTimeout: const Duration(seconds: 3),
      checkInterval: const Duration(seconds: 5),
    ),
  );
}

/// Register core services with performance optimization
Future<void> _registerCoreServices() async {
  // Network Info - Cached for performance
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // RBAC Services - Singletons for security consistency
  sl.registerLazySingleton(() => RoleManager());
  sl.registerLazySingleton(() => RBACService());
}

/// Register Auth feature with comprehensive security
Future<void> _registerAuthFeature() async {
  // BLoC - Factory for proper lifecycle management
  sl.registerFactory(
    () => AuthBloc(
      signInWithGoogleUseCase: sl(),
      signOutUseCase: sl(),
      isAuthenticatedUseCase: sl(),
      getCurrentUserUseCase: sl(),
      authRepository: sl(),
    ),
  );

  // Use Cases - Lazy singletons for performance
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => IsAuthenticated(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));

  // Repository - Singleton with enhanced error handling
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      firebaseAuthDataSource: sl(),
      supabaseUserDataSource: sl(),
    ),
  );

  // Data Sources - Production-ready implementations
  sl.registerLazySingleton<FirebaseAuthDataSource>(
    () => FirebaseAuthDataSourceImpl(firebaseAuth: sl(), googleSignIn: sl()),
  );

  sl.registerLazySingleton<SupabaseUserDataSource>(
    () => SupabaseUserDataSourceImpl(supabaseClient: sl()),
  );
}

/// Security: Validate all critical registrations
Future<void> _validateRegistrations() async {
  final criticalServices = [
    AuthBloc,
    AuthRepository,
    FirebaseAuthDataSource,
    SupabaseUserDataSource,
    RBACService,
  ];

  for (final serviceType in criticalServices) {
    try {
      final instance = sl.get(type: serviceType);
      // Fixed: Remove null check - GetIt throws if not registered
      print('✅ Service validated: $serviceType');
    } catch (e) {
      throw Exception('Service validation failed for $serviceType: $e');
    }
  }

  // Validate connectivity
  try {
    final supabaseDataSource = sl<SupabaseUserDataSource>();
    if (supabaseDataSource is SupabaseUserDataSourceImpl) {
      final isConnected = await supabaseDataSource.validateConnection();
      if (!isConnected) {
        print(
          '⚠️ Supabase connection validation failed - App will work in offline mode',
        );
      }
    }
  } catch (e) {
    print('⚠️ Connection validation error: $e');
  }
}

/// Production: Clear sensitive initialization data
Future<void> _clearSensitiveData() async {
  // Clear any temporary initialization data
  // This would include any debug information, temporary tokens, etc.
  // Implementation depends on specific security requirements
}

/// Development: Get dependency health status
Map<String, dynamic> getDependencyHealthStatus() {
  if (const bool.fromEnvironment('dart.vm.product')) {
    return {'status': 'production_mode'};
  }

  return {
    'firebase_registered': sl.isRegistered<FirebaseAuth>(),
    'supabase_registered': sl.isRegistered<SupabaseClient>(),
    'auth_bloc_factory': sl.isRegistered<AuthBloc>(),
    'auth_repository': sl.isRegistered<AuthRepository>(),
    'rbac_service': sl.isRegistered<RBACService>(),
    'network_info': sl.isRegistered<NetworkInfo>(),
    'total_registrations': _getRegistrationCount(),
  };
}

/// Helper method to safely get registration count
int _getRegistrationCount() {
  try {
    // Fixed: GetIt.allReadySync() returns bool, not collection
    // Use alternative approach to count registrations
    int count = 0;
    final services = [
      FirebaseAuth,
      SupabaseClient,
      GoogleSignIn,
      InternetConnectionChecker,
      NetworkInfo,
      RoleManager,
      RBACService,
      AuthBloc,
      SignInWithGoogle,
      SignOut,
      IsAuthenticated,
      GetCurrentUser,
      AuthRepository,
      FirebaseAuthDataSource,
      SupabaseUserDataSource,
    ];

    for (final service in services) {
      if (sl.isRegistered(type: service)) count++;
    }

    return count;
  } catch (e) {
    return 0;
  }
}

/// Cleanup for testing or app shutdown
Future<void> cleanup() async {
  await sl.reset();
  print('🧹 DI Container cleaned up');
}
