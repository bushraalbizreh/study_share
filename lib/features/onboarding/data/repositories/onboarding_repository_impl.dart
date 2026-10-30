import 'package:app_study_share/core/storage/local_store.dart';
import 'package:app_study_share/features/onboarding/domain/repositories/onboarding_repository.dart';

/// Persists onboarding completion in the Hive-backed [LocalStore].
class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this.store);

  static const onboardingCompletedKey = 'onboarding_completed';
  final LocalStore store;

  @override
  Future<bool> markCompleted() async {
    await store.setBool(onboardingCompletedKey, true);
    return true;
  }

  @override
  Future<bool> isCompleted() async => store.getBool(onboardingCompletedKey);
}
