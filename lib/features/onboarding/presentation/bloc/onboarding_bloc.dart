import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_study_share/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({OnboardingRepository? onboardingRepository})
    : _onboardingRepository = onboardingRepository,
      super(const OnboardingInitial()) {
    on<OnboardingPageChanged>(_onOnboardingPageChanged);
    on<OnboardingCompleted>(_onOnboardingCompleted);
  }

  final OnboardingRepository? _onboardingRepository;

  Future<void> _onOnboardingPageChanged(
    OnboardingPageChanged event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingPage(page: event.page));
  }

  Future<void> _onOnboardingCompleted(
    OnboardingCompleted event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(const OnboardingLoading());
    final onboardingRepository = _onboardingRepository;
    if (onboardingRepository != null) {
      await onboardingRepository.markCompleted();
    }
    emit(const OnboardingCompletedState());
  }
}


