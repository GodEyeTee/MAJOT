import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/is_authenticated.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithGoogle signInWithGoogleUseCase;
  final SignOut signOutUseCase;
  final IsAuthenticated isAuthenticatedUseCase;

  AuthBloc({
    required this.signInWithGoogleUseCase,
    required this.signOutUseCase,
    required this.isAuthenticatedUseCase,
  }) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignOutEvent>(_onSignOut);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final isAuthResult = await isAuthenticatedUseCase(const NoParams());

    isAuthResult.fold((failure) => emit(AuthError(message: failure.message)), (
      isAuth,
    ) {
      if (isAuth) {
        emit(const Authenticated());
      } else {
        emit(Unauthenticated());
      }
    });
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await signInWithGoogleUseCase(const NoParams());

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(Authenticated(user: user)),
    );
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await signOutUseCase(const NoParams());

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(Unauthenticated()),
    );
  }
}
