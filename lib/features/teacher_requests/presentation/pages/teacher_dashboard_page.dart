import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/routing/route_names.dart';
import 'package:app_study_share/core/session/session.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:app_study_share/features/study_groups/presentation/widgets/study_group_card.dart';
import 'package:app_study_share/features/teacher_requests/presentation/bloc/teacher_requests_bloc.dart';
import 'package:app_study_share/features/teacher_requests/presentation/bloc/teacher_requests_event.dart';
import 'package:app_study_share/features/teacher_requests/presentation/bloc/teacher_requests_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key, this.onOpenProfile});

  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) => BlocProvider<TeacherRequestsBloc>(
    create: (_) => getIt<TeacherRequestsBloc>()..add(const RequestsRequested()),
    child: _View(onOpenProfile: onOpenProfile),
  );
}

class _View extends StatelessWidget {
  const _View({this.onOpenProfile});

  final VoidCallback? onOpenProfile;

  Future<void> _open(BuildContext context, StudyGroup g) async {
    final bloc = context.read<TeacherRequestsBloc>();
    await Navigator.of(context).pushNamed(RouteNames.requestDetails, arguments: {'groupId': g.id});
    bloc.add(const RequestsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final user = getIt<Session>().user;
    final name = user?.name ?? '';
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('dashboard.title')),
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
      body: BlocConsumer<TeacherRequestsBloc, TeacherRequestsState>(
        listenWhen: (_, c) => c is RequestDecisionSucceeded || c is RequestDecisionFailed,
        listener: (context, state) {
          if (state is RequestDecisionSucceeded) {
            showFeedback(context, context.tr(state.accepted ? 'request.acceptedDone' : 'request.rejectedDone'));
          } else if (state is RequestDecisionFailed) {
            showFeedback(context, context.errorText(state.code, state.message), error: true);
          }
          context.read<TeacherRequestsBloc>().add(const RequestsRequested());
        },
        buildWhen: (_, c) => c is TeacherRequestsLoaded || c is TeacherRequestsLoading || c is TeacherRequestsError,
        builder: (context, state) {
          if (state is TeacherRequestsError) {
            return StateView.error(
              message: context.errorText(state.code, state.message),
              onAction: () => context.read<TeacherRequestsBloc>().add(const RequestsRequested()),
            );
          }
          if (state is! TeacherRequestsLoaded) return const StateView.loading();
          final pending = state.pending;
          final accepted = state.accepted;
          return RefreshIndicator(
            onRefresh: () async => context.read<TeacherRequestsBloc>().add(const RequestsRequested()),
            child: ListView(
              children: [
                ResponsiveBody(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: onOpenProfile,
                            customBorder: const CircleBorder(),
                            child: UserAvatar(name: name, imageUrl: user?.imageUrl, radius: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.tr('dashboard.hello', {'name': name}),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _Stat(value: pending.length, label: context.tr('dashboard.pending'), highlight: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _Stat(value: accepted.length, label: context.tr('dashboard.accepted'))),
                        ],
                      ),
                      SectionTitle(context.tr('dashboard.awaiting')),
                      if (pending.isEmpty)
                        StateView.empty(
                          icon: Icons.inbox_rounded,
                          title: context.tr('dashboard.noPending'),
                          message: context.tr('dashboard.noPendingHint'),
                        ),
                      for (final g in pending)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: StudyGroupCard(
                            group: g,
                            onTap: () => _open(context, g),
                            footer: Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                                    onPressed: () => context.read<TeacherRequestsBloc>().add(RequestAccepted(g.id)),
                                    child: Text(context.tr('request.accept')),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(44),
                                      foregroundColor: scheme.error,
                                      side: BorderSide(color: scheme.error),
                                    ),
                                    onPressed: () async {
                                      final bloc = context.read<TeacherRequestsBloc>();
                                      final ok = await confirmDialog(
                                        context,
                                        title: context.tr('request.reject'),
                                        message: context.tr('request.rejectConfirm'),
                                        confirmLabel: context.tr('request.reject'),
                                      );
                                      if (ok) bloc.add(RequestRejected(g.id));
                                    },
                                    child: Text(context.tr('request.reject')),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (accepted.isNotEmpty) SectionTitle(context.tr('dashboard.acceptedList')),
                      for (final g in accepted)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: StudyGroupCard(group: g, onTap: () => _open(context, g)),
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
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.highlight = false});

  final int value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: highlight ? scheme.primary : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: highlight ? scheme.onPrimary : scheme.primary,
              ),
            ),
            Text(label, style: TextStyle(color: highlight ? scheme.onPrimary : scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
