import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../services/rbac/rbac_service.dart';
import '../../domain/usecases/is_authenticated.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithGoogle signInWithGoogleUseCase;
  final SignOut signOutUseCase;
  final IsAuthenticated isAuthenticatedUseCase;
  final GetCurrentUser getCurrentUserUseCase;
  final AuthRepository authRepository;
  final RBACService _rbacService;

  late final StreamSubscription _authStateSubscription;
  bool _isInitialized = false;
  User? _cachedUser;

  AuthBloc({
    required this.signInWithGoogleUseCase,
    required this.signOutUseCase,
    required this.isAuthenticatedUseCase,
    required this.getCurrentUserUseCase,
    required this.authRepository,
    RBACService? rbacService,
  }) : _rbacService = rbacService ?? RBACService(),
       super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignOutEvent>(_onSignOut);
    on<AuthStateChangedEvent>(_onAuthStateChanged);
    on<RefreshUserDataEvent>(_onRefreshUserData);

    _initializeAuthStateMonitoring();
  }

  void _initializeAuthStateMonitoring() {
    _authStateSubscription = authRepository.authStateChanges.listen((
      userResult,
    ) {
      userResult.fold(
        (failure) {
          LoggerService.error(
            'Auth state change failure: ${failure.message}',
            'AUTH_BLOC',
          );
          add(AuthStateChangedEvent(failure: failure));
        },
        (user) {
          LoggerService.info(
            'Auth state changed: ${user?.email ?? 'signed out'}',
            'AUTH_BLOC',
          );
          add(AuthStateChangedEvent(user: user));
        },
      );
    });
  }

  Future<void> _onAuthStateChanged(
    AuthStateChangedEvent event,
    Emitter<AuthState> emit,
  ) async {
    _isInitialized = true;

    if (event.failure != null) {
      emit(AuthError(message: event.failure!.message));
      return;
    }

    if (event.user != null) {
      _cachedUser = event.user;
      _rbacService.setCurrentUser(event.user);
      emit(Authenticated(user: event.user));
    } else {
      _cachedUser = null;
      _rbacService.setCurrentUser(null);
      emit(Unauthenticated());
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (!_isInitialized) {
      emit(AuthLoading());
    }

    final result = await getCurrentUserUseCase(const NoParams());
    result.fold(
      (failure) {
        LoggerService.error(
          'Check auth status failed: ${failure.message}',
          'AUTH_BLOC',
        );
        emit(AuthError(message: failure.message));
      },
      (user) {
        _isInitialized = true;
        if (user != null) {
          _cachedUser = user;
          _rbacService.setCurrentUser(user);
          emit(Authenticated(user: user));
        } else {
          _cachedUser = null;
          _rbacService.setCurrentUser(null);
          emit(Unauthenticated());
        }
      },
    );
  }

  Future<void> _onRefreshUserData(
    RefreshUserDataEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    LoggerService.info('Refreshing user data', 'AUTH_BLOC');

    if (authRepository is AuthRepositoryImpl) {
      final result =
          await (authRepository as AuthRepositoryImpl).forceGetCurrentUser();
      result.fold(
        (failure) {
          LoggerService.error(
            'Refresh user data failed: ${failure.message}',
            'AUTH_BLOC',
          );
          emit(AuthError(message: failure.message));
        },
        (user) {
          if (user != null) {
            _cachedUser = user;
            _rbacService.setCurrentUser(user);
            emit(Authenticated(user: user));
            LoggerService.info('User data refreshed successfully', 'AUTH_BLOC');
          } else {
            emit(Unauthenticated());
          }
        },
      );
    } else {
      // Fallback to regular getCurrentUser
      final result = await getCurrentUserUseCase(const NoParams());
      result.fold((failure) => emit(AuthError(message: failure.message)), (
        user,
      ) {
        if (user != null) {
          _cachedUser = user;
          _rbacService.setCurrentUser(user);
          emit(Authenticated(user: user));
        } else {
          emit(Unauthenticated());
        }
      });
    }
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    LoggerService.info('Starting Google sign-in', 'AUTH_BLOC');

    final result = await signInWithGoogleUseCase(const NoParams());
    result.fold(
      (failure) {
        LoggerService.error(
          'Google sign-in failed: ${failure.message}',
          'AUTH_BLOC',
        );
        emit(AuthError(message: failure.message));
      },
      (user) {
        LoggerService.info(
          'Google sign-in successful: ${user.email}',
          'AUTH_BLOC',
        );
        // Success handled by auth stream
      },
    );
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    LoggerService.info('Starting sign-out', 'AUTH_BLOC');

    final result = await signOutUseCase(const NoParams());
    result.fold(
      (failure) {
        LoggerService.error('Sign-out failed: ${failure.message}', 'AUTH_BLOC');
        emit(AuthError(message: failure.message));
      },
      (_) {
        LoggerService.info('Sign-out successful', 'AUTH_BLOC');
        // Success handled by auth stream
      },
    );
  }

  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => state is Authenticated;
  User? get currentUser => _cachedUser;

  @override
  Future<void> close() async {
    await _authStateSubscription.cancel();
    return super.close();
  }
}
