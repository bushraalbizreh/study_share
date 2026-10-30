import 'package:app_study_share/core/utils/guard.dart';
import 'package:app_study_share/features/notifications/domain/entities/app_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.groupId,
    required super.subject,
    required super.read,
    required super.createdAt,
  });

  factory AppNotificationModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return AppNotificationModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      type: d['type'] as String? ?? '',
      groupId: d['groupId'] as String? ?? '',
      subject: d['subject'] as String? ?? '',
      read: d['read'] as bool? ?? false,
      createdAt: toDate(d['createdAt']),
    );
  }
}
