import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:app_study_share/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:app_study_share/features/splash/presentation/bloc/splash_event.dart';
import 'package:app_study_share/features/splash/presentation/bloc/splash_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocProvider<SplashBloc>(
      create: (_) => getIt<SplashBloc>()..add(const SplashAppStarted()),
      child: BlocListener<SplashBloc, SplashState>(
        listener: (context, state) {
          if (state is SplashLoaded) {
            Navigator.of(context).pushReplacementNamed(state.route);
          }
        },
        child: Scaffold(
          backgroundColor: scheme.primary,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.onPrimary,
                    borderRadius: BorderRadius.circular(34),
                  ),
                  child: const BrandMark(size: 84),
                ),
                const SizedBox(height: 24),
                Text(
                  'StudyShare',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontSize: 34,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('splash.tagline'),
                  style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: scheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
