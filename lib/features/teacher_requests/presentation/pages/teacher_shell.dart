import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/session/session.dart';
import 'package:app_study_share/features/availability/presentation/pages/teacher_availability_page.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:app_study_share/features/profile/presentation/pages/profile_settings_page.dart';
import 'package:app_study_share/features/teacher_requests/presentation/pages/teacher_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  static const _profileTab = 2;

  int _index = 0;
  final Set<int> _visited = {0};

  @override
  void initState() {
    super.initState();
    final uid = getIt<Session>().user?.uid;
    if (uid != null) context.read<NotificationsBloc>().add(NotificationsStarted(uid));
  }

  void _select(int i) => setState(() {
    _index = i;
    _visited.add(i);
  });

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      TeacherDashboardPage(onOpenProfile: () => _select(_profileTab)),
      const TeacherAvailabilityPage(),
      const ProfileSettingsPage(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < pages.length; i++)
            _visited.contains(i) ? pages[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.inbox_outlined),
            selectedIcon: const Icon(Icons.inbox_rounded),
            label: context.tr('nav.requests'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_outlined),
            selectedIcon: const Icon(Icons.event_rounded),
            label: context.tr('nav.availability'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: context.tr('nav.profile'),
          ),
        ],
      ),
    );
  }
}
