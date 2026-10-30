import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/routing/route_names.dart';
import 'package:app_study_share/core/utils/firestore_paths.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:app_study_share/features/study_groups/presentation/bloc/study_groups_bloc.dart';
import 'package:app_study_share/features/study_groups/presentation/bloc/study_groups_event.dart';
import 'package:app_study_share/features/study_groups/presentation/bloc/study_groups_state.dart';
import 'package:app_study_share/features/study_groups/presentation/widgets/study_group_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyGroupsPage extends StatelessWidget {
  const MyGroupsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<StudyGroupsBloc>(
    create: (_) => getIt<StudyGroupsBloc>()..add(const MyGroupsRequested()),
    child: const _View(),
  );
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  String? _status;

  static const _statuses = [
    GroupStatus.open,
    GroupStatus.pending,
    GroupStatus.accepted,
    GroupStatus.rejected,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('mygroups.title'))),
      body: ResponsiveBody(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final s in <String?>[null, ..._statuses])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text(
                          s == null ? context.tr('level.all') : context.tr('status.${s.toLowerCase()}'),
                        ),
                        selected: _status == s,
                        onSelected: (_) => setState(() => _status = s),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<StudyGroupsBloc, StudyGroupsState>(
                builder: (context, state) {
                  if (state is StudyGroupsError) {
                    return StateView.error(
                      message: context.errorText(state.code, state.message),
                      onAction: () =>
                          context.read<StudyGroupsBloc>().add(const MyGroupsRequested()),
                    );
                  }
                  if (state is! MyGroupsLoaded) return const StateView.loading();
                  final groups = state.groups
                      .where((g) => _status == null || g.status == _status)
                      .toList();
                  return RefreshIndicator(
                    onRefresh: () async =>
                        context.read<StudyGroupsBloc>().add(const MyGroupsRequested()),
                    child: groups.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 60),
                              StateView.empty(
                                icon: Icons.groups_2_outlined,
                                title: context.tr('mygroups.empty'),
                                message: context.tr('mygroups.emptyHint'),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: groups.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, i) => StudyGroupCard(
                              group: groups[i],
                              onTap: () async {
                                final bloc = context.read<StudyGroupsBloc>();
                                await Navigator.of(context).pushNamed(
                                  RouteNames.groupDetails,
                                  arguments: {'groupId': groups[i].id},
                                );
                                bloc.add(const MyGroupsRequested());
                              },
                            ),
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
