import 'package:app_study_share/core/utils/firestore_paths.dart';
import 'package:equatable/equatable.dart';

/// A study group booked against one teacher slot.
/// Membership, capacity and status are changed only by Cloud Functions.
class StudyGroup extends Equatable {
  const StudyGroup({
    required this.id,
    required this.creatorId,
    required this.teacherId,
    required this.teacherName,
    required this.slotId,
    required this.startAt,
    required this.durationMinutes,
    required this.subject,
    required this.gradeLevel,
    required this.pricePerStudent,
    required this.capacity,
    required this.memberIds,
    required this.memberNames,
    required this.notes,
    required this.status,
  });

  final String id;
  final String creatorId;
  final String teacherId;
  final String teacherName;
  final String slotId;
  final DateTime startAt;
  final int durationMinutes;
  final String subject;

  /// `elementary`, `middle` or `high`.
  final String gradeLevel;
  final int pricePerStudent;

  /// Total students including the creator.
  final int capacity;
  final List<String> memberIds;
  final Map<String, String> memberNames;
  final String notes;
  final String status;

  int get currentMembers => memberIds.length;
  bool get isFull => currentMembers >= capacity;
  bool get isOpen => status == GroupStatus.open;
  bool get isChatAvailable => status == GroupStatus.accepted;
  bool hasMember(String uid) => memberIds.contains(uid);

  @override
  List<Object?> get props => [
    id, creatorId, teacherId, teacherName, slotId, startAt, durationMinutes,
    subject, gradeLevel, pricePerStudent, capacity, memberIds, memberNames,
    notes, status,
  ];
}
