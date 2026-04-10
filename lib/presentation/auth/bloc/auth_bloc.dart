import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/admin/user.dart';
import 'package:suki_pos/domain/use_cases/auth/login.dart';

/// [PRESENTATION LAYER]
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  const LoginEvent(this.pin);
  final String pin;
  @override
  List<Object?> get props => [pin];
}

class LogoutEvent extends AuthEvent {}

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;
  @override
  List<Object?> get props => [user];
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required this.loginUseCase}) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
  }

  final Login loginUseCase;

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await loginUseCase(event.pin);
    result.fold(
      (failure) => emit(const AuthError('Invalid PIN or account inactive')),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  void _onLogout(LogoutEvent event, Emitter<AuthState> emit) {
    emit(AuthUnauthenticated());
  }
}
