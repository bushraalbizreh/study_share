import 'package:app_study_share/features/notifications/domain/entities/app_notification.dart';
import 'package:equatable/equatable.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

/// Starts listening for the signed-in user's notifications and registers the
/// device for push.
class NotificationsStarted extends NotificationsEvent {
  const NotificationsStarted(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class NotificationsStopped extends NotificationsEvent {
  const NotificationsStopped();
}

class NotificationMarkedRead extends NotificationsEvent {
  const NotificationMarkedRead(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class NotificationsAllMarkedRead extends NotificationsEvent {
  const NotificationsAllMarkedRead();
}

/// Permanently deletes every notification of the signed-in user.
class NotificationsAllDeleted extends NotificationsEvent {
  const NotificationsAllDeleted();
}

/// Internal: stream emissions.
class NotificationsUpdated extends NotificationsEvent {
  const NotificationsUpdated(this.items);

  final List<AppNotification> items;

  @override
  List<Object?> get props => [items];
}

class NotificationsStreamFailed extends NotificationsEvent {
  const NotificationsStreamFailed(this.message, this.code);

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
