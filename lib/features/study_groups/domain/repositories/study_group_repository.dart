import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';

/// Contract for the student-facing study group workflow. Every mutation is a
/// trusted Cloud Function call (transactions enforce capacity and status).
abstract class StudyGroupRepository {
  Future<List<StudyGroup>> getStudentGroups({required String studentId});

  Future<StudyGroup?> getGroupDetails({required String groupId});

  /// Returns the new group's id.
  Future<String> createGroup({
    required String teacherId,
    required String subject,
    required String gradeLevel,
    required String slotId,
    required String notes,
    required int capacity,
  });

  Future<void> joinGroup({required String groupId});

  Future<void> leaveGroup({required String groupId});
}
