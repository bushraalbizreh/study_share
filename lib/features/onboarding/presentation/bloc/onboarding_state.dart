import 'package:equatable/equatable.dart';

sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();

  @override
  List<Object?> get props => [];
}

class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();

  @override
  List<Object?> get props => [];
}

class OnboardingPage extends OnboardingState {
  const OnboardingPage({required this.page});

  final int page;

  @override
  List<Object?> get props => [page];
}

class OnboardingCompletedState extends OnboardingState {
  const OnboardingCompletedState();

  @override
  List<Object?> get props => [];
}


