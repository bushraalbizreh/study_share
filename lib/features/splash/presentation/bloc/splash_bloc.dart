import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/core/routing/route_names.dart';
import 'package:app_study_share/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_study_share/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'splash_event.dart';
import 'splash_state.dart';

/// Decides the first route from real state: onboarding flag, Firebase session
/// and the signed-in user's role.
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc({
    required AuthRepository authRepository,
    required OnboardingRepository onboardingRepository,
    this.minDisplay = const Duration(milliseconds: 1200),
  }) : _auth = authRepository,
       _onboarding = onboardingRepository,
       super(const SplashInitial()) {
    on<SplashAppStarted>(_onStarted);
  }

  final AuthRepository _auth;
  final OnboardingRepository _onboarding;
  final Duration minDisplay;

  Future<void> _onStarted(SplashAppStarted event, Emitter<SplashState> emit) async {
    emit(const SplashLoading());
    final minimum = Future<void>.delayed(minDisplay);
    String route;
    try {
      final user = await _auth.getCurrentUser();
      if (user != null) {
        route = RouteNames.homeFor(user.role);
      } else {
        route = await _onboarding.isCompleted() ? RouteNames.login : RouteNames.onboarding;
      }
    } on Failure {
      route = RouteNames.login;
    }
    await minimum;
    emit(SplashLoaded(route: route));
  }
}
