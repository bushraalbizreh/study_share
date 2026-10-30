import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/routing/route_names.dart';
import 'package:app_study_share/core/utils/firestore_paths.dart';
import 'package:app_study_share/core/utils/ui_helpers.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:app_study_share/features/teacher_requests/presentation/bloc/teacher_requests_bloc.dart';
import 'package:app_study_share/features/teacher_requests/presentation/bloc/teacher_requests_event.dart';
import 'package:app_study_share/features/teacher_requests/presentation/bloc/teacher_requests_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RequestDetailsPage extends StatelessWidget {
  const RequestDetailsPage({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) => BlocProvider<TeacherRequestsBloc>(
    create: (_) => getIt<TeacherRequestsBloc>()..add(RequestDetailsRequested(groupId)),
    child: Scaffold(
      appBar: AppBar(title: Text(context.tr('request.title'))),
      body: BlocConsumer<TeacherRequestsBloc, TeacherRequestsState>(
        listenWhen: (_, c) => c is RequestDecisionSucceeded || c is RequestDecisionFailed,
        listener: (context, state) {
          if (state is RequestDecisionSucceeded) {
            showFeedback(context, context.tr(state.accepted ? 'request.acceptedDone' : 'request.rejectedDone'));
            Navigator.of(context).pop(true);
          } else if (state is RequestDecisionFailed) {
            showFeedback(context, context.errorText(state.code, state.message), error: true);
          }
        },
        buildWhen: (_, c) => c is RequestDetailsLoaded || c is TeacherRequestsLoading || c is TeacherRequestsError,
        builder: (context, state) => switch (state) {
          RequestDetailsLoaded(group: final g?) => _Body(group: g),
          RequestDetailsLoaded() => StateView.empty(icon: Icons.inbox_rounded, title: context.tr('group.gone')),
          TeacherRequestsError() => StateView.error(
            message: context.errorText(state.code, state.message),
            onAction: () => context.read<TeacherRequestsBloc>().add(RequestDetailsRequested(groupId)),
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
    final pending = group.status == GroupStatus.pending;
    final total = group.pricePerStudent * group.currentMembers;
    return SingleChildScrollView(
      child: ResponsiveBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(group.subject, style: Theme.of(context).textTheme.headlineSmall)),
                StatusChip(group.status),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    InfoRow(context.tr('group.when'), context.when(group.startAt)),
                    InfoRow(context.tr('group.duration'), '${group.durationMinutes}′'),
                    InfoRow(context.tr('group.level'), context.levelLabel(group.gradeLevel)),
                    InfoRow(context.tr('group.price'), context.priceLabel(group.pricePerStudent)),
                    InfoRow(context.tr('request.expected'), context.priceLabel(total), emphasis: true),
                  ],
                ),
              ),
            ),
            SectionTitle(
              context.tr('request.students'),
              trailing: Text('${group.currentMembers}/${group.capacity}', style: TextStyle(color: scheme.onSurfaceVariant)),
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
            if (pending) ...[
              PrimaryButton(
                label: context.tr('request.accept'),
                icon: Icons.check_rounded,
                onPressed: () => context.read<TeacherRequestsBloc>().add(RequestAccepted(group.id)),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: context.tr('request.reject'),
                outlined: true,
                onPressed: () async {
                  final bloc = context.read<TeacherRequestsBloc>();
                  final ok = await confirmDialog(
                    context,
                    title: context.tr('request.reject'),
                    message: context.tr('request.rejectConfirm'),
                    confirmLabel: context.tr('request.reject'),
                  );
                  if (ok) bloc.add(RequestRejected(group.id));
                },
              ),
            ],
            if (group.isChatAvailable)
              PrimaryButton(
                label: context.tr('group.openChat'),
                icon: Icons.forum_rounded,
                onPressed: () => Navigator.of(context).pushNamed(
                  RouteNames.groupChat,
                  arguments: {'groupId': group.id, 'title': group.subject},
                ),
              ),
          ],
        ),
      ),
    );
  }
}
