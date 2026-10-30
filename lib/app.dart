import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/localization/locale_bloc.dart';
import 'package:app_study_share/core/routing/app_router.dart';
import 'package:app_study_share/core/theme/app_theme.dart';
import 'package:app_study_share/core/theme/theme_bloc.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_bloc.dart';

class StudyShareApp extends StatelessWidget {
  StudyShareApp({super.key});

  final AppRouter _router = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>.value(value: getIt<ThemeBloc>()..add(const ThemeAppStarted())),
        BlocProvider<LocaleBloc>.value(value: getIt<LocaleBloc>()..add(const LocaleAppStarted())),
        BlocProvider<NotificationsBloc>.value(value: getIt<NotificationsBloc>()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final themeMode = themeState is ThemeLoaded
              ? themeState.mode
              : ThemeMode.system;
          return BlocBuilder<LocaleBloc, LocaleState>(
            builder: (context, localeState) {
              final locale = localeState is LocaleLoaded
                  ? localeState.locale
                  : const Locale('en');

              return MaterialApp(
                title: 'StudyShare',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,
                locale: locale,
                navigatorKey: _router.navigatorKey,
                onGenerateRoute: _router.generateRoute,
                initialRoute: AppRouter.initialRoute,
                localizationsDelegates: [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
              );
            },
          );
        },
      ),
    );
  }
}


