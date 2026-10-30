import 'package:app_study_share/features/notifications/domain/entities/app_notification.dart';
import 'package:equatable/equatable.dart';

sealed class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded(this.items);

  final List<AppNotification> items;

  int get unreadCount => items.where((n) => !n.read).length;

  @override
  List<Object?> get props => [items];
}

class NotificationsError extends NotificationsState {
  const NotificationsError({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
