import 'package:app_study_share/core/routing/route_names.dart';
import 'package:app_study_share/features/auth/domain/entities/user.dart';
import 'package:app_study_share/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_study_share/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:app_study_share/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:app_study_share/features/splash/presentation/bloc/splash_event.dart';
import 'package:app_study_share/features/splash/presentation/bloc/splash_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends Mock implements AuthRepository {}

class _Onboarding extends Mock implements OnboardingRepository {}

void main() {
  late _Auth auth;
  late _Onboarding onboarding;

  setUp(() {
    auth = _Auth();
    onboarding = _Onboarding();
  });

  SplashBloc build() => SplashBloc(
    authRepository: auth,
    onboardingRepository: onboarding,
    minDisplay: Duration.zero,
  );

  blocTest<SplashBloc, SplashState>(
    'first launch goes to onboarding',
    build: () {
      when(() => auth.getCurrentUser()).thenAnswer((_) async => null);
      when(() => onboarding.isCompleted()).thenAnswer((_) async => false);
      return build();
    },
    act: (b) => b.add(const SplashAppStarted()),
    expect: () => [const SplashLoading(), const SplashLoaded(route: RouteNames.onboarding)],
  );

  blocTest<SplashBloc, SplashState>(
    'returning signed-out user goes to login',
    build: () {
      when(() => auth.getCurrentUser()).thenAnswer((_) async => null);
      when(() => onboarding.isCompleted()).thenAnswer((_) async => true);
      return build();
    },
    act: (b) => b.add(const SplashAppStarted()),
    expect: () => [const SplashLoading(), const SplashLoaded(route: RouteNames.login)],
  );

  blocTest<SplashBloc, SplashState>(
    'a teacher lands on the teacher home',
    build: () {
      when(() => auth.getCurrentUser()).thenAnswer(
        (_) async => const User(uid: 't', email: 'a@b.c', name: 'T', role: 'teacher'),
      );
      return build();
    },
    act: (b) => b.add(const SplashAppStarted()),
    expect: () => [const SplashLoading(), const SplashLoaded(route: RouteNames.teacherHome)],
  );
}
