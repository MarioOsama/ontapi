import 'package:equatable/equatable.dart';

import '../data/models/app_user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final AppUser user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthSignUpStageOne extends AuthState {
  final String email;
  final String password;

  const AuthSignUpStageOne({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthBranchSelection extends AuthState {
  final AppUser user;

  const AuthBranchSelection(this.user);

  @override
  List<Object?> get props => [user];
}
