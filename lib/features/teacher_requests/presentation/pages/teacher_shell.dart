import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/session/session.dart';
import 'package:app_study_share/features/availability/presentation/pages/teacher_availability_page.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:app_study_share/features/notifications/presentation/pages/notifications_page.dart';
import 'package:app_study_share/features/profile/presentation/pages/profile_settings_page.dart';
import 'package:app_study_share/features/teacher_requests/presentation/pages/teacher_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Teacher home: Requests / Availability / Notifications / Profile.
class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _index = 0;
  final Set<int> _visited = {0};

  @override
  void initState() {
    super.initState();
    final uid = getIt<Session>().user?.uid;
    if (uid != null) context.read<NotificationsBloc>().add(NotificationsStarted(uid));
  }

  static const _pages = <Widget>[
    TeacherDashboardPage(),
    TeacherAvailabilityPage(),
    NotificationsPage(),
    ProfileSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < _pages.length; i++)
            _visited.contains(i) ? _pages[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() {
          _index = i;
          _visited.add(i);
        }),
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
            icon: BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, s) {
                final n = s is NotificationsLoaded ? s.unreadCount : 0;
                return Badge(
                  isLabelVisible: n > 0,
                  label: Text('$n'),
                  child: const Icon(Icons.notifications_outlined),
                );
              },
            ),
            selectedIcon: const Icon(Icons.notifications_rounded),
            label: context.tr('nav.notifications'),
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
