import 'package:app_study_share/features/notifications/domain/entities/app_notification.dart';
import 'package:app_study_share/features/notifications/domain/repositories/notifications_repository.dart';

abstract class NotificationsUseCase {
  Stream<List<AppNotification>> watch({required String userId});

  Future<void> markRead({required String notificationId});

  Future<void> markAllRead({required String userId});

  Future<void> deleteAll({required String userId});

  Future<void> registerDevice();

  Future<void> unregisterDevice();
}

class NotificationsUseCaseImpl implements NotificationsUseCase {
  NotificationsUseCaseImpl(this.repository);

  final NotificationsRepository repository;

  @override
  Stream<List<AppNotification>> watch({required String userId}) =>
      repository.watchNotifications(userId: userId);

  @override
  Future<void> markRead({required String notificationId}) =>
      repository.markRead(notificationId: notificationId);

  @override
  Future<void> markAllRead({required String userId}) =>
      repository.markAllRead(userId: userId);

  @override
  Future<void> deleteAll({required String userId}) =>
      repository.deleteAll(userId: userId);

  @override
  Future<void> registerDevice() => repository.registerDevice();

  @override
  Future<void> unregisterDevice() => repository.unregisterDevice();
}
