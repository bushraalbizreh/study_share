import 'package:app_study_share/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:flutter/material.dart';

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) => const OnboardingScaffold(
    index: 1,
    icon: Icons.manage_search_rounded,
    satellites: [Icons.school_rounded, Icons.star_rounded],
  );
}
