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

Future<void> init() async {
  //! Features - Auth

  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      signInWithGoogleUseCase: sl(),
      signOutUseCase: sl(),
      isAuthenticatedUseCase: sl(),
      getCurrentUserUseCase: sl(),
      authRepository: sl(), // สำหรับ authStateChanges
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => IsAuthenticated(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      firebaseAuthDataSource: sl(),
      supabaseUserDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<FirebaseAuthDataSource>(
    () => FirebaseAuthDataSourceImpl(firebaseAuth: sl(), googleSignIn: sl()),
  );
  sl.registerLazySingleton<SupabaseUserDataSource>(
    () => SupabaseUserDataSourceImpl(supabaseClient: sl()),
  );

  //! Core Services

  // RBAC Services
  sl.registerLazySingleton(() => RoleManager());
  sl.registerLazySingleton(() => RBACService());

  // Network
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  //! External Dependencies

  // Firebase
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => GoogleSignIn());

  // Supabase
  sl.registerLazySingleton(() => Supabase.instance.client);

  // Network
  sl.registerLazySingleton(() => InternetConnectionChecker());

  print('✅ Dependency Injection initialized successfully');
}
