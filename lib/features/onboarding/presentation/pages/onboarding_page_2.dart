import 'package:app_study_share/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:flutter/material.dart';

class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key});

  @override
  Widget build(BuildContext context) => const OnboardingScaffold(
    index: 2,
    icon: Icons.groups_rounded,
    satellites: [Icons.event_available_rounded, Icons.payments_outlined],
  );
}
