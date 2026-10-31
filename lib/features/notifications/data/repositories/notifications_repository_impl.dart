import 'package:app_study_share/core/utils/guard.dart';
import 'package:app_study_share/features/notifications/data/datasources/notifications_remote_source.dart';
import 'package:app_study_share/features/notifications/domain/entities/app_notification.dart';
import 'package:app_study_share/features/notifications/domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this.remote);

  final NotificationsRemoteSource remote;

  @override
  Stream<List<AppNotification>> watchNotifications({required String userId}) =>
      remote.watchNotifications(userId: userId);

  @override
  Future<void> markRead({required String notificationId}) =>
      guardCall(() => remote.markRead(notificationId: notificationId));

  @override
  Future<void> markAllRead({required String userId}) =>
      guardCall(() => remote.markAllRead(userId: userId));

  @override
  Future<void> deleteAll({required String userId}) =>
      guardCall(() => remote.deleteAll(userId: userId));

  @override
  Future<void> registerDevice() => guardCall(remote.registerDevice);

  @override
  Future<void> unregisterDevice() => guardCall(remote.unregisterDevice);
}
