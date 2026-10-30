import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/routing/route_names.dart';
import 'package:app_study_share/core/session/session.dart';
import 'package:app_study_share/core/utils/firestore_paths.dart';
import 'package:app_study_share/core/utils/ui_helpers.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:app_study_share/features/study_groups/presentation/bloc/study_groups_bloc.dart';
import 'package:app_study_share/features/study_groups/presentation/bloc/study_groups_event.dart';
import 'package:app_study_share/features/study_groups/presentation/bloc/study_groups_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupDetailsPage extends StatelessWidget {
  const GroupDetailsPage({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) => BlocProvider<StudyGroupsBloc>(
    create: (_) => getIt<StudyGroupsBloc>()..add(GroupDetailsRequested(groupId)),
    child: Scaffold(
      appBar: AppBar(title: Text(context.tr('group.title'))),
      body: BlocConsumer<StudyGroupsBloc, StudyGroupsState>(
        listenWhen: (_, c) => c is StudyGroupActionSucceeded || c is StudyGroupActionFailed,
        listener: (context, state) {
          if (state is StudyGroupActionSucceeded) {
            showFeedback(context, context.tr('group.done.${state.action}'));
            if (state.action == 'left') Navigator.of(context).maybePop();
          } else if (state is StudyGroupActionFailed) {
            showFeedback(context, context.errorText(state.code, state.message), error: true);
          }
        },
        buildWhen: (_, c) =>
            c is GroupDetailsLoaded || c is StudyGroupsLoading || c is StudyGroupsError,
        builder: (context, state) => switch (state) {
          GroupDetailsLoaded(group: final g?) => _Body(group: g),
          GroupDetailsLoaded() => StateView.empty(
            icon: Icons.group_off_rounded,
            title: context.tr('group.gone'),
            message: context.tr('group.goneHint'),
          ),
          StudyGroupsError() => StateView.error(
            message: context.errorText(state.code, state.message),
            onAction: () => context.read<StudyGroupsBloc>().add(GroupDetailsRequested(groupId)),
          ),
          _ => const StateView.loading(),
        },
      ),
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.group});

  final StudyGroup group;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = getIt<Session>();
    final uid = session.user?.uid ?? '';
    final isMember = group.hasMember(uid);
    final isAssignedTeacher = session.isTeacher && group.teacherId == uid;
    final canJoin = session.isStudent && !isMember && group.isOpen && !group.isFull;
    final canLeave = session.isStudent && isMember && group.isOpen;
    final canChat = group.isChatAvailable && (isMember || isAssignedTeacher);

    final banner = switch (group.status) {
      GroupStatus.pending => ('group.pendingInfo', Icons.hourglass_top_rounded),
      GroupStatus.rejected => ('group.rejectedInfo', Icons.block_rounded),
      GroupStatus.accepted => ('group.acceptedInfo', Icons.check_circle_rounded),
      _ => null,
    };

    return SingleChildScrollView(
      child: ResponsiveBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(group.subject, style: Theme.of(context).textTheme.headlineSmall),
                ),
                StatusChip(group.status),
              ],
            ),
            if (banner != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(banner.$2, color: scheme.onSecondaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr(banner.$1),
                        style: TextStyle(color: scheme.onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pushNamed(
                        RouteNames.teacherProfile,
                        arguments: {'teacherId': group.teacherId},
                      ),
                      child: InfoRow(context.tr('group.teacher'), group.teacherName),
                    ),
                    InfoRow(context.tr('group.when'), context.when(group.startAt)),
                    InfoRow(context.tr('group.duration'), '${group.durationMinutes}′'),
                    InfoRow(context.tr('group.level'), context.levelLabel(group.gradeLevel)),
                    InfoRow(
                      context.tr('group.price'),
                      context.priceLabel(group.pricePerStudent),
                      emphasis: true,
                    ),
                  ],
                ),
              ),
            ),
            SectionTitle(
              context.tr('group.membersTitle'),
              trailing: Text(
                context.tr('group.members', {
                  'n': '${group.currentMembers}',
                  'm': '${group.capacity}',
                }),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    for (final id in group.memberIds)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: UserAvatar(name: group.memberNames[id] ?? '?', radius: 18),
                        title: Text(group.memberNames[id] ?? '—'),
                        trailing: id == group.creatorId
                            ? Text(
                                context.tr('group.creator'),
                                style: TextStyle(color: scheme.primary, fontSize: 12),
                              )
                            : null,
                      ),
                  ],
                ),
              ),
            ),
            if (group.notes.trim().isNotEmpty) ...[
              SectionTitle(context.tr('group.notes')),
              Text(group.notes, style: const TextStyle(height: 1.6)),
            ],
            const SizedBox(height: 20),
            if (canJoin)
              PrimaryButton(
                label: context.tr('group.join'),
                icon: Icons.login_rounded,
                onPressed: () => context.read<StudyGroupsBloc>().add(StudyGroupJoined(group.id)),
              ),
            if (canLeave)
              PrimaryButton(
                label: context.tr('group.leave'),
                outlined: true,
                onPressed: () async {
                  final bloc = context.read<StudyGroupsBloc>();
                  final ok = await confirmDialog(
                    context,
                    title: context.tr('group.leave'),
                    message: context.tr('group.leaveConfirm'),
                    confirmLabel: context.tr('group.leave'),
                  );
                  if (ok) bloc.add(StudyGroupLeft(group.id));
                },
              ),
            if (canChat) ...[
              const SizedBox(height: 10),
              PrimaryButton(
                label: context.tr('group.openChat'),
                icon: Icons.forum_rounded,
                onPressed: () => Navigator.of(context).pushNamed(
                  RouteNames.groupChat,
                  arguments: {'groupId': group.id, 'title': group.subject},
                ),
              ),
            ],
            if (isAssignedTeacher && group.status == GroupStatus.pending) ...[
              const SizedBox(height: 10),
              PrimaryButton(
                label: context.tr('group.reviewRequest'),
                onPressed: () => Navigator.of(context).pushNamed(
                  RouteNames.requestDetails,
                  arguments: {'groupId': group.id},
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
