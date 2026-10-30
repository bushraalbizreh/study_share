import 'package:equatable/equatable.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class OnboardingPageChanged extends OnboardingEvent {
  const OnboardingPageChanged({required this.page});

  final int page;

  @override
  List<Object?> get props => [page];
}

class OnboardingCompleted extends OnboardingEvent {
  const OnboardingCompleted();

  @override
  List<Object?> get props => [];
}


