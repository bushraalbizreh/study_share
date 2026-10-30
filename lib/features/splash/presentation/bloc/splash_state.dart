import 'package:equatable/equatable.dart';

sealed class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {
  const SplashInitial();

  @override
  List<Object?> get props => [];
}

class SplashLoading extends SplashState {
  const SplashLoading();

  @override
  List<Object?> get props => [];
}

class SplashLoaded extends SplashState {
  const SplashLoaded({required this.route});

  final String route;

  @override
  List<Object?> get props => [route];
}


