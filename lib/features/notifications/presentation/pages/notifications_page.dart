import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/routing/route_names.dart';
import 'package:app_study_share/core/session/session.dart';
import 'package:app_study_share/core/utils/formatters.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:app_study_share/features/notifications/domain/entities/app_notification.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Uses the app-level [NotificationsBloc] provided above the Navigator.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const _icons = {
    'group_full': Icons.group_add_rounded,
    'group_accepted': Icons.check_circle_rounded,
    'group_rejected': Icons.cancel_rounded,
  };

  void _open(BuildContext context, AppNotification n) {
    context.read<NotificationsBloc>().add(NotificationMarkedRead(n.id));
    if (n.groupId.isEmpty) return;
    final teacher = getIt<Session>().isTeacher;
    Navigator.of(context).pushNamed(
      teacher ? RouteNames.requestDetails : RouteNames.groupDetails,
      arguments: {'groupId': n.groupId},
    );
  }

  void _deleteAll(BuildContext context) {
    context.read<NotificationsBloc>().add(const NotificationsAllDeleted());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('notifications.title')),
        actions: [
          IconButton(
            tooltip: context.tr('notifications.markAll'),
            icon: const Icon(Icons.done_all_rounded),
            onPressed: () => context.read<NotificationsBloc>().add(const NotificationsAllMarkedRead()),
          ),
        ],
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsError) {
            return StateView.error(message: context.errorText(state.code, state.message));
          }
          if (state is! NotificationsLoaded) return const StateView.loading();
          if (state.items.isEmpty) {
            return StateView.empty(
              icon: Icons.notifications_none_rounded,
              title: context.tr('notifications.empty'),
              message: context.tr('notifications.emptyHint'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
            itemCount: state.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final n = state.items[i];
              return Card(
                color: n.read ? null : scheme.primaryContainer.withValues(alpha: 0.5),
                child: ListTile(
                  onTap: () => _open(context, n),
                  leading: CircleAvatar(
                    backgroundColor: scheme.secondaryContainer,
                    foregroundColor: scheme.primary,
                    child: Icon(_icons[n.type] ?? Icons.notifications_rounded),
                  ),
                  title: Text(
                    context.tr('notif.${n.type}.title'),
                    style: TextStyle(fontWeight: n.read ? FontWeight.w500 : FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${context.tr('notif.${n.type}.body', {'subject': n.subject})}\n${Formatters.dateTimeLabel(context, n.createdAt)}',
                  ),
                  isThreeLine: true,
                  trailing: n.read ? null : Icon(Icons.circle, size: 10, color: scheme.primary),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: BlocBuilder<NotificationsBloc, NotificationsState>(
        buildWhen: (prev, curr) {
          final a = prev is NotificationsLoaded && prev.items.isNotEmpty;
          final b = curr is NotificationsLoaded && curr.items.isNotEmpty;
          return a != b;
        },
        builder: (context, state) {
          final hasItems = state is NotificationsLoaded && state.items.isNotEmpty;
          if (!hasItems) return const SizedBox.shrink();
          return FloatingActionButton.small(
            heroTag: 'deleteAllNotifications',
            tooltip: context.tr('notifications.deleteAll'),
            onPressed: () => _deleteAll(context),
            child: const Icon(Icons.delete_outline_rounded),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
