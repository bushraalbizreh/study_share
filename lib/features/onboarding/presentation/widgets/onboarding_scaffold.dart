import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/routing/route_names.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:app_study_share/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:app_study_share/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:app_study_share/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shared layout for the three onboarding screens (index is 1-based).
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({super.key, required this.index, required this.icon, this.satellites = const []});

  final int index;
  final IconData icon;

  final List<IconData> satellites;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OnboardingBloc>(
      create: (_) => getIt<OnboardingBloc>(),
      child: BlocListener<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingCompletedState) {
            Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.login, (_) => false);
          }
        },
        child: Builder(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            final last = index == 3;
            return Scaffold(
              body: SafeArea(
                child: ResponsiveBody(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: () => context.read<OnboardingBloc>().add(const OnboardingCompleted()),
                          child: Text(context.tr('onboarding.skip')),
                        ),
                      ),
                      Expanded(
                        child: Center(child: _Art(icon: icon, satellites: satellites)),
                      ),
                      Text(
                        context.tr('onboarding.$index.title'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.tr('onboarding.$index.body'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant, height: 1.6),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 1; i <= 3; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == index ? 26 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == index ? scheme.primary : scheme.outlineVariant,
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      BlocBuilder<OnboardingBloc, OnboardingState>(
                        builder: (context, state) => PrimaryButton(
                          label: context.tr(last ? 'onboarding.start' : 'action.next'),
                          loading: state is OnboardingLoading,
                          onPressed: () {
                            if (last) {
                              context.read<OnboardingBloc>().add(const OnboardingCompleted());
                            } else {
                              Navigator.of(context).pushNamed(
                                index == 1 ? RouteNames.onboarding2 : RouteNames.onboarding3,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Art extends StatelessWidget {
  const _Art({required this.icon, required this.satellites});

  final IconData icon;
  final List<IconData> satellites;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
          ),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
            child: Icon(icon, size: 72, color: scheme.onPrimary),
          ),
          for (var i = 0; i < satellites.length; i++)
            Positioned(
              top: i == 0 ? 8 : null,
              bottom: i == 1 ? 14 : null,
              left: i == 0 ? 20 : null,
              right: i == 1 ? 14 : (i == 2 ? 0 : null),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: scheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                child: Icon(satellites[i], size: 26),
              ),
            ),
        ],
      ),
    );
  }
}
