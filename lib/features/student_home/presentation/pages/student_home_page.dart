import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/routing/route_names.dart';
import 'package:app_study_share/core/session/session.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:app_study_share/features/discovery/presentation/pages/explore_page.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:app_study_share/features/profile/presentation/pages/profile_settings_page.dart';
import 'package:app_study_share/features/student_home/presentation/bloc/student_home_bloc.dart';
import 'package:app_study_share/features/student_home/presentation/bloc/student_home_event.dart';
import 'package:app_study_share/features/student_home/presentation/bloc/student_home_state.dart';
import 'package:app_study_share/features/study_groups/presentation/pages/my_groups_page.dart';
import 'package:app_study_share/features/study_groups/presentation/widgets/study_group_card.dart';
import 'package:app_study_share/features/teacher_profile/presentation/widgets/teacher_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Student home: Home / Explore / My groups / Profile.
class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
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
      _HomeTab(onSelectTab: _select),
      const ExplorePage(),
      const MyGroupsPage(),
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
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: context.tr('nav.home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_rounded),
            selectedIcon: const Icon(Icons.manage_search_rounded),
            label: context.tr('nav.explore'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_2_outlined),
            selectedIcon: const Icon(Icons.groups_2_rounded),
            label: context.tr('nav.groups'),
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

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.onSelectTab});

  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) => BlocProvider<StudentHomeBloc>(
    create: (_) => getIt<StudentHomeBloc>()..add(const StudentHomeRequested()),
    child: Builder(
      builder: (context) {
        final name = getIt<Session>().user?.name ?? '';
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: Text(context.tr('home.title')),
            actions: [
              BlocBuilder<NotificationsBloc, NotificationsState>(
                builder: (context, s) {
                  final n = s is NotificationsLoaded ? s.unreadCount : 0;
                  return IconButton(
                    tooltip: context.tr('notifications.title'),
                    onPressed: () => Navigator.of(context).pushNamed(RouteNames.notifications),
                    icon: Badge(
                      isLabelVisible: n > 0,
                      label: Text('$n'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                  );
                },
              ),
            ],
          ),
          body: BlocBuilder<StudentHomeBloc, StudentHomeState>(
            builder: (context, state) {
              if (state is StudentHomeError) {
                return StateView.error(
                  message: context.errorText(state.code, state.message),
                  onAction: () => context.read<StudentHomeBloc>().add(const StudentHomeRequested()),
                );
              }
              if (state is! StudentHomeLoaded) return const StateView.loading();
              final d = state.data;
              final next = d.next;
              return RefreshIndicator(
                onRefresh: () async => context.read<StudentHomeBloc>().add(const StudentHomeRequested()),
                child: ListView(
                  children: [
                    ResponsiveBody(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () => onSelectTab(3),
                                customBorder: const CircleBorder(),
                                child: UserAvatar(
                                  name: name,
                                  imageUrl: getIt<Session>().user?.imageUrl,
                                  radius: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  context.tr('home.hello', {'name': name}),
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (next != null)
                            StudyGroupCard(
                              group: next,
                              onTap: () => Navigator.of(context).pushNamed(
                                RouteNames.groupDetails,
                                arguments: {'groupId': next.id},
                              ),
                            )
                          else
                            Card(
                              color: scheme.primary,
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('home.noNext'),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      context.tr('home.noNextHint'),
                                      style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.85)),
                                    ),
                                    const SizedBox(height: 12),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: scheme.secondary,
                                        foregroundColor: scheme.onSecondary,
                                        minimumSize: const Size(160, 44),
                                      ),
                                      onPressed: () => onSelectTab(1),
                                      child: Text(context.tr('home.explore')),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          SectionTitle(
                            context.tr('home.teachers'),
                            trailing: TextButton(onPressed: () => onSelectTab(1), child: Text(context.tr('action.seeAll'))),
                          ),
                          if (d.teachers.isEmpty)
                            Text(context.tr('explore.noTeachers'), style: TextStyle(color: scheme.onSurfaceVariant)),
                          for (final t in d.teachers)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TeacherCard(
                                teacher: t,
                                onTap: () => Navigator.of(context).pushNamed(
                                  RouteNames.teacherProfile,
                                  arguments: {'teacherId': t.uid},
                                ),
                              ),
                            ),
                          SectionTitle(context.tr('home.openGroups')),
                          if (d.openGroups.isEmpty)
                            Text(context.tr('explore.noGroups'), style: TextStyle(color: scheme.onSurfaceVariant)),
                          for (final g in d.openGroups)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: StudyGroupCard(
                                group: g,
                                onTap: () => Navigator.of(context).pushNamed(
                                  RouteNames.groupDetails,
                                  arguments: {'groupId': g.id},
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ),
  );
}
