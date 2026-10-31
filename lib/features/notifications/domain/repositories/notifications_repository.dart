import 'package:app_study_share/features/notifications/domain/entities/app_notification.dart';

abstract class NotificationsRepository {
  /// Live list of the user's notifications, newest first.
  Stream<List<AppNotification>> watchNotifications({required String userId});

  Future<void> markRead({required String notificationId});

  Future<void> markAllRead({required String userId});

  /// Permanently removes every notification belonging to [userId].
  Future<void> deleteAll({required String userId});

  /// Asks for permission, stores the FCM token under the signed-in user and
  /// keeps it fresh on token rotation.
  Future<void> registerDevice();

  /// Removes this device's token so a signed-out device stops receiving pushes.
  Future<void> unregisterDevice();
}
