import 'package:app_study_share/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:flutter/material.dart';

class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  @override
  Widget build(BuildContext context) => const OnboardingScaffold(
    index: 3,
    icon: Icons.forum_rounded,
    satellites: [Icons.check_circle_rounded, Icons.notifications_active_rounded],
  );
}
