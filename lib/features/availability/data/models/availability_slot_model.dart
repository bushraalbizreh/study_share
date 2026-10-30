import 'package:app_study_share/core/utils/guard.dart';
import 'package:app_study_share/features/availability/domain/entities/availability_slot.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvailabilitySlotModel extends AvailabilitySlot {
  const AvailabilitySlotModel({
    required super.id,
    required super.teacherId,
    required super.startAt,
    required super.durationMinutes,
    required super.status,
    super.groupId,
  });

  factory AvailabilitySlotModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return AvailabilitySlotModel(
      id: doc.id,
      teacherId: d['teacherId'] as String? ?? '',
      startAt: toDate(d['startAt']),
      durationMinutes: (d['durationMinutes'] as num?)?.toInt() ?? 60,
      status: d['status'] as String? ?? 'available',
      groupId: d['groupId'] as String?,
    );
  }

  static Map<String, dynamic> createMap({
    required String teacherId,
    required DateTime startAt,
    required int durationMinutes,
  }) => {
    'teacherId': teacherId,
    'startAt': Timestamp.fromDate(startAt),
    'durationMinutes': durationMinutes,
    'status': 'available',
    'groupId': null,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
