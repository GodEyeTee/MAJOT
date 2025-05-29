import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
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
import 'dart:async';

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
        (failure) => add(AuthStateChangedEvent(failure: failure)),
        (user) => add(AuthStateChangedEvent(user: user)),
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
    result.fold((failure) => emit(AuthError(message: failure.message)), (user) {
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
    });
  }

  Future<void> _onRefreshUserData(
    RefreshUserDataEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // ใช้ forceGetCurrentUser แทน
    if (authRepository is AuthRepositoryImpl) {
      final result =
          await (authRepository as AuthRepositoryImpl).forceGetCurrentUser();
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
    final result = await signInWithGoogleUseCase(const NoParams());
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) {}, // Success handled by auth stream
    );
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await signOutUseCase(const NoParams());
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) {}, // Success handled by auth stream
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
