import 'package:equatable/equatable.dart';

sealed class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object?> get props => [];
}

class SplashAppStarted extends SplashEvent {
  const SplashAppStarted();

  @override
  List<Object?> get props => [];
}


