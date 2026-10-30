import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/routing/route_names.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:app_study_share/features/discovery/presentation/bloc/discovery_bloc.dart';
import 'package:app_study_share/features/discovery/presentation/bloc/discovery_event.dart';
import 'package:app_study_share/features/discovery/presentation/bloc/discovery_state.dart';
import 'package:app_study_share/features/study_groups/presentation/widgets/study_group_card.dart';
import 'package:app_study_share/features/teacher_profile/presentation/widgets/teacher_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<DiscoveryBloc>(
    create: (_) => getIt<DiscoveryBloc>()..add(const ExploreRequested()),
    child: const _ExploreView(),
  );
}

class _ExploreView extends StatelessWidget {
  const _ExploreView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('explore.title'))),
      body: ResponsiveBody(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: Column(
          children: [
            TextField(
              onChanged: (v) => context.read<DiscoveryBloc>().add(ExploreQueryChanged(v)),
              decoration: InputDecoration(
                hintText: context.tr('explore.search'),
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            BlocBuilder<DiscoveryBloc, DiscoveryState>(
              builder: (context, state) {
                final s = state is DiscoveryLoaded ? state : null;
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<int>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(value: 0, label: Text(context.tr('explore.teachers'))),
                          ButtonSegment(value: 1, label: Text(context.tr('explore.groups'))),
                        ],
                        selected: {s?.tab ?? 0},
                        onSelectionChanged: (v) =>
                            context.read<DiscoveryBloc>().add(ExploreTabChanged(v.first)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final l in <String?>[null, ...kLevels])
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: ChoiceChip(
                                label: Text(l == null ? context.tr('level.all') : context.tr('level.$l')),
                                selected: (s?.level) == l,
                                onSelected: (_) =>
                                    context.read<DiscoveryBloc>().add(ExploreLevelChanged(l)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<DiscoveryBloc, DiscoveryState>(
                builder: (context, state) {
                  if (state is DiscoveryError) {
                    return StateView.error(
                      message: context.errorText(state.code, state.message),
                      onAction: () => context.read<DiscoveryBloc>().add(const ExploreRequested()),
                    );
                  }
                  if (state is! DiscoveryLoaded) return const StateView.loading();
                  final items = state.tab == 0 ? state.teachers : state.groups;
                  return RefreshIndicator(
                    onRefresh: () async =>
                        context.read<DiscoveryBloc>().add(const ExploreRequested()),
                    child: items.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 60),
                              StateView.empty(
                                icon: Icons.search_off_rounded,
                                title: context.tr(
                                  state.tab == 0 ? 'explore.noTeachers' : 'explore.noGroups',
                                ),
                                message: context.tr('explore.emptyHint'),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              if (state.tab == 0) {
                                final t = state.teachers[i];
                                return TeacherCard(
                                  teacher: t,
                                  onTap: () => Navigator.of(context).pushNamed(
                                    RouteNames.teacherProfile,
                                    arguments: {'teacherId': t.uid},
                                  ),
                                );
                              }
                              final g = state.groups[i];
                              return StudyGroupCard(
                                group: g,
                                onTap: () => Navigator.of(context).pushNamed(
                                  RouteNames.groupDetails,
                                  arguments: {'groupId': g.id},
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
