import 'package:app_study_share/core/utils/guard.dart';
import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudyGroupModel extends StudyGroup {
  const StudyGroupModel({
    required super.id,
    required super.creatorId,
    required super.teacherId,
    required super.teacherName,
    required super.slotId,
    required super.startAt,
    required super.durationMinutes,
    required super.subject,
    required super.gradeLevel,
    required super.pricePerStudent,
    required super.capacity,
    required super.memberIds,
    required super.memberNames,
    required super.notes,
    required super.status,
  });

  factory StudyGroupModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return StudyGroupModel(
      id: doc.id,
      creatorId: d['creatorId'] as String? ?? '',
      teacherId: d['teacherId'] as String? ?? '',
      teacherName: d['teacherName'] as String? ?? '',
      slotId: d['slotId'] as String? ?? '',
      startAt: toDate(d['startAt']),
      durationMinutes: (d['durationMinutes'] as num?)?.toInt() ?? 60,
      subject: d['subject'] as String? ?? '',
      gradeLevel: d['gradeLevel'] as String? ?? 'middle',
      pricePerStudent: (d['pricePerStudent'] as num?)?.toInt() ?? 0,
      capacity: (d['capacity'] as num?)?.toInt() ?? 0,
      memberIds: ((d['memberIds'] as List?) ?? const []).cast<String>(),
      memberNames: ((d['memberNames'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(k as String, v as String),
      ),
      notes: d['notes'] as String? ?? '',
      status: d['status'] as String? ?? 'Open',
    );
  }
}
