import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/features/auth/domain/usecases/current_user_usecase.dart';
import 'package:app_study_share/features/auth/domain/usecases/login_usecase.dart';
import 'package:app_study_share/features/auth/domain/usecases/logout_usecase.dart';
import 'package:app_study_share/features/auth/domain/usecases/register_usecase.dart';
import 'package:app_study_share/features/auth/domain/usecases/reset_password_usecase.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required CurrentUserUseCase currentUserUseCase,
    required LoginUserUseCase loginUserUseCase,
    required RegisterUserUseCase registerUserUseCase,
    required LogoutUserUseCase logoutUserUseCase,
    required ResetPasswordUserUseCase resetPasswordUserUseCase,
  }) : _currentUserUseCase = currentUserUseCase,
       _loginUserUseCase = loginUserUseCase,
       _registerUserUseCase = registerUserUseCase,
       _logoutUserUseCase = logoutUserUseCase,
       _resetPasswordUserUseCase = resetPasswordUserUseCase,
       super(const AuthInitial()) {
    on<AuthUserSignedIn>(_onAuthUserSignedIn);
    on<AuthUserSignedOut>(_onAuthUserSignedOut);
    on<AuthUserSignedUp>(_onAuthUserSignedUp);
    on<AuthCurrentUserRequested>(_onAuthCurrentUserRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
  }

  final CurrentUserUseCase _currentUserUseCase;
  final LoginUserUseCase _loginUserUseCase;
  final RegisterUserUseCase _registerUserUseCase;
  final LogoutUserUseCase _logoutUserUseCase;
  final ResetPasswordUserUseCase _resetPasswordUserUseCase;

  Future<void> _onAuthUserSignedIn(
    AuthUserSignedIn event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _loginUserUseCase.execute(
        email: event.email,
        password: event.password,
      );
      final user = await _currentUserUseCase.execute();
      emit(
        user != null ? AuthAuthenticated(user) : const AuthUnauthenticated(),
      );
    } on Failure catch (failure) {
      emit(AuthError(message: failure.message, code: failure.code));
    }
  }

  Future<void> _onAuthUserSignedOut(
    AuthUserSignedOut event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _logoutUserUseCase.execute();
      emit(const AuthUnauthenticated());
    } on Failure catch (failure) {
      emit(AuthError(message: failure.message, code: failure.code));
    }
  }

  Future<void> _onAuthUserSignedUp(
    AuthUserSignedUp event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _registerUserUseCase.execute(
        email: event.email,
        password: event.password,
        name: event.name,
        role: event.role,
      );
      final user = await _currentUserUseCase.execute();
      emit(
        user != null ? AuthAuthenticated(user) : const AuthUnauthenticated(),
      );
    } on Failure catch (failure) {
      emit(AuthError(message: failure.message, code: failure.code));
    }
  }

  Future<void> _onAuthCurrentUserRequested(
    AuthCurrentUserRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _currentUserUseCase.execute();
      emit(
        user != null ? AuthAuthenticated(user) : const AuthUnauthenticated(),
      );
    } on Failure catch (failure) {
      emit(AuthError(message: failure.message, code: failure.code));
    }
  }

  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _resetPasswordUserUseCase.execute(email: event.email);
      emit(AuthResetEmailSent(email: event.email));
    } on Failure catch (failure) {
      emit(AuthError(message: failure.message, code: failure.code));
    }
  }
}


