import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../services/rbac/rbac_service.dart';
import '../../domain/usecases/is_authenticated.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'dart:async';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithGoogle signInWithGoogleUseCase;
  final SignOut signOutUseCase;
  final IsAuthenticated isAuthenticatedUseCase;
  final GetCurrentUser getCurrentUserUseCase;
  final AuthRepository authRepository;
  final RBACService _rbacService = RBACService();

  late final StreamSubscription _authStateSubscription;
  bool _isInitialized = false;

  AuthBloc({
    required this.signInWithGoogleUseCase,
    required this.signOutUseCase,
    required this.isAuthenticatedUseCase,
    required this.getCurrentUserUseCase,
    required this.authRepository,
  }) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignOutEvent>(_onSignOut);
    on<AuthStateChangedEvent>(_onAuthStateChanged);

    // Listen to auth state changes
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
    if (event.failure != null) {
      emit(AuthError(message: event.failure!.message));
      return;
    }

    _isInitialized = true;

    if (event.user != null) {
      _rbacService.setCurrentUser(event.user);
      emit(Authenticated(user: event.user));
    } else {
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

    // ถ้า initialized แล้ว และยังไม่มี current state ที่ชัดเจน
    // ให้ check อีกครั้ง
    if (_isInitialized && state is AuthInitial) {
      final result = await getCurrentUserUseCase(const NoParams());
      result.fold((failure) => emit(AuthError(message: failure.message)), (
        user,
      ) {
        if (user != null) {
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

    result.fold((failure) => emit(AuthError(message: failure.message)), (user) {
      // State จะถูก update ผ่าน authStateChanges stream automatically
      print('✅ Sign in successful: ${user.email}');
    });
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await signOutUseCase(const NoParams());

    result.fold((failure) => emit(AuthError(message: failure.message)), (_) {
      // State จะถูก update ผ่าน authStateChanges stream automatically
      print('✅ Sign out successful');
    });
  }

  // Getter สำหรับ router
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => state is Authenticated;

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }
}
