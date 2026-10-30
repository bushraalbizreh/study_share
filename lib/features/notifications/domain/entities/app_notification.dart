import 'package:equatable/equatable.dart';

/// In-app notification. `type` is `group_full`, `group_accepted` or
/// `group_rejected`; the text is localized on the client from type + subject.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.groupId,
    required this.subject,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String type;
  final String groupId;
  final String subject;
  final bool read;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, userId, type, groupId, subject, read, createdAt];
}
