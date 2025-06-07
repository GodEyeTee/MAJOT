import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:my_test_app/features/ocr_scanner/presentation/bloc/scanner_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core
import '../network/network_info.dart';
import '../services/supabase_service_client.dart';

// Auth feature
import '../../features/auth/data/datasources/firebase_auth_data_source.dart';
import '../../features/auth/data/datasources/supabase_user_data_source.dart'
    as auth;
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/is_authenticated.dart';
import '../../features/auth/domain/usecases/sign_in_with_google.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Theme feature
import '../../features/theme/data/datasources/theme_local_data_source.dart';
import '../../features/theme/data/repositories/theme_repository_impl.dart';
import '../../features/theme/domain/repositories/theme_repository.dart';
import '../../features/theme/domain/usecases/get_theme_preference.dart';
import '../../features/theme/domain/usecases/save_theme_preference.dart';
import '../../features/theme/domain/usecases/watch_theme_changes.dart';
import '../../features/theme/presentation/bloc/theme_bloc.dart';

// Services
import '../../services/rbac/role_manager.dart';
import '../../services/rbac/rbac_service.dart';

// Profile feature
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile.dart';
import '../../features/profile/domain/usecases/update_profile.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

// Privacy & Security feature
import '../../features/privacy_security/data/datasources/security_remote_data_source.dart';
import '../../features/privacy_security/data/repositories/security_repository_impl.dart';
import '../../features/privacy_security/domain/repositories/security_repository.dart';
import '../../features/privacy_security/domain/usecases/get_security_settings.dart';
import '../../features/privacy_security/presentation/bloc/security_bloc.dart';

// Hotel feature
import '../../features/hotel/data/datasources/room_remote_data_source.dart';
import '../../features/hotel/data/datasources/tenant_remote_data_source.dart';
import '../../features/hotel/data/datasources/meter_remote_data_source.dart';
import '../../features/hotel/data/datasources/bill_remote_data_source.dart';
import '../../features/hotel/data/repositories/room_repository_impl.dart';
import '../../features/hotel/data/repositories/tenant_repository_impl.dart';
import '../../features/hotel/data/repositories/meter_repository_impl.dart';
import '../../features/hotel/data/repositories/bill_repository_impl.dart';
import '../../features/hotel/domain/repositories/room_repository.dart';
import '../../features/hotel/domain/repositories/tenant_repository.dart';
import '../../features/hotel/domain/repositories/meter_repository.dart';
import '../../features/hotel/domain/repositories/bill_repository.dart';
import '../../features/hotel/domain/usecases/room/get_rooms.dart';
import '../../features/hotel/domain/usecases/room/create_room.dart';
import '../../features/hotel/domain/usecases/meter/get_latest_reading.dart';
import '../../features/hotel/domain/usecases/meter/save_meter_reading.dart';
import '../../features/hotel/presentation/bloc/room/room_bloc.dart';
import '../../features/hotel/presentation/bloc/meter/meter_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  await _registerExternalDependencies();
  await _registerCoreServices();
  await _registerAuthFeature();
  await _registerThemeFeature();
  await _registerProfileFeature();
  await _registerSecurityFeature();
  await _registerScannerFeature();
  await _registerHotelFeature();
}

Future<void> _registerSecurityFeature() async {
  // Data sources
  sl.registerLazySingleton<SecurityRemoteDataSource>(
    () => SecurityRemoteDataSourceImpl(supabaseClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<SecurityRepository>(
    () => SecurityRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetSecuritySettings(sl()));

  // BLoC
  sl.registerFactory(
    () => SecurityBloc(getSecuritySettingsUseCase: sl(), repository: sl()),
  );
}

Future<void> _registerProfileFeature() async {
  // Data sources - ไม่ต้องส่ง parameter เพราะใช้ singleton
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(),
  );

  // Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProfile(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));

  // BLoC
  sl.registerFactory(
    () => ProfileBloc(getProfileUseCase: sl(), updateProfileUseCase: sl()),
  );
}

Future<void> _registerExternalDependencies() async {
  // Firebase
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<GoogleSignIn>(
    () => GoogleSignIn(scopes: ['email', 'profile']),
  );

  // Supabase - Regular client (for public operations)
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Supabase - Service client (for RLS bypass operations)
  sl.registerLazySingleton<SupabaseServiceClient>(
    () => SupabaseServiceClient(),
  );

  // Network
  sl.registerLazySingleton<InternetConnectionChecker>(
    () => InternetConnectionChecker.createInstance(),
  );

  // Local Storage
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
}

Future<void> _registerCoreServices() async {
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl<InternetConnectionChecker>()),
  );
  sl.registerLazySingleton<RoleManager>(() => RoleManager());
  sl.registerLazySingleton<RBACService>(() => RBACService());
}

Future<void> _registerAuthFeature() async {
  // Data sources
  sl.registerLazySingleton<FirebaseAuthDataSource>(
    () => FirebaseAuthDataSourceImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      googleSignIn: sl<GoogleSignIn>(),
    ),
  );

  // *** แก้ไขตรงนี้ - ใช้ SupabaseServiceClient แทน SupabaseClient ***
  sl.registerLazySingleton<auth.SupabaseUserDataSource>(
    () => auth.SupabaseUserDataSourceImpl(
      serviceClient: sl<SupabaseServiceClient>(), // ใช้ service client
    ),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      firebaseAuthDataSource: sl<FirebaseAuthDataSource>(),
      supabaseUserDataSource: sl<auth.SupabaseUserDataSource>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton<SignInWithGoogle>(
    () => SignInWithGoogle(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<SignOut>(() => SignOut(sl<AuthRepository>()));
  sl.registerLazySingleton<IsAuthenticated>(
    () => IsAuthenticated(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetCurrentUser>(
    () => GetCurrentUser(sl<AuthRepository>()),
  );

  // BLoC
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      signInWithGoogleUseCase: sl<SignInWithGoogle>(),
      signOutUseCase: sl<SignOut>(),
      isAuthenticatedUseCase: sl<IsAuthenticated>(),
      getCurrentUserUseCase: sl<GetCurrentUser>(),
      authRepository: sl<AuthRepository>(),
    ),
  );
}

Future<void> _registerThemeFeature() async {
  // Data sources
  sl.registerLazySingleton<ThemeLocalDataSource>(
    () => ThemeLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Repository
  sl.registerLazySingleton<ThemeRepository>(
    () => ThemeRepositoryImpl(localDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetThemePreference(sl()));
  sl.registerLazySingleton(() => SaveThemePreference(sl()));
  sl.registerLazySingleton(() => WatchThemeChanges(sl()));

  // BLoC
  sl.registerFactory(
    () => ThemeBloc(
      getThemePreference: sl(),
      saveThemePreference: sl(),
      watchThemeChanges: sl(),
    ),
  );
}

Future<void> _registerScannerFeature() async {
  // BLoC
  sl.registerFactory(() => ScannerBloc());
}

Future<void> _registerHotelFeature() async {
  // Data sources
  sl.registerLazySingleton<RoomRemoteDataSource>(
    () => RoomRemoteDataSourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<TenantRemoteDataSource>(
    () => TenantRemoteDataSourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<MeterRemoteDataSource>(
    () => MeterRemoteDataSourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<BillRemoteDataSource>(
    () => BillRemoteDataSourceImpl(supabaseClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<RoomRepository>(
    () => RoomRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<TenantRepository>(
    () => TenantRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<MeterRepository>(
    () => MeterRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<BillRepository>(
    () => BillRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases - Room
  sl.registerLazySingleton(() => GetRooms(sl()));
  sl.registerLazySingleton(() => CreateRoom(sl()));

  // Use cases - Meter
  sl.registerLazySingleton(() => GetLatestReading(sl()));
  sl.registerLazySingleton(() => SaveMeterReading(sl()));

  // BLoCs
  sl.registerFactory(() => RoomBloc(getRooms: sl(), createRoom: sl()));
  sl.registerFactory(
    () => MeterBloc(getLatestReading: sl(), saveMeterReading: sl()),
  );
}
