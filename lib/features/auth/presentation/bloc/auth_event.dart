import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthUserSignedIn extends AuthEvent {
  const AuthUserSignedIn({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthUserSignedOut extends AuthEvent {
  const AuthUserSignedOut();

  @override
  List<Object?> get props => [];
}

class AuthUserSignedUp extends AuthEvent {
  const AuthUserSignedUp({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });

  final String email;
  final String password;
  final String name;
  final String role;

  @override
  List<Object?> get props => [email, password, name, role];
}

class AuthCurrentUserRequested extends AuthEvent {
  const AuthCurrentUserRequested();

  @override
  List<Object?> get props => [];
}

class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}


