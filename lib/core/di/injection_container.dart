import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

// Core
import '../network/network_info.dart';
import '../services/supabase_service_client.dart';

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

Future<void> init() async {
  await _registerExternalDependencies();
  await _registerCoreServices();
  await _registerAuthFeature();
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
  sl.registerLazySingleton<SupabaseUserDataSource>(
    () => SupabaseUserDataSourceImpl(
      serviceClient: sl<SupabaseServiceClient>(), // ใช้ service client
    ),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      firebaseAuthDataSource: sl<FirebaseAuthDataSource>(),
      supabaseUserDataSource: sl<SupabaseUserDataSource>(),
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
