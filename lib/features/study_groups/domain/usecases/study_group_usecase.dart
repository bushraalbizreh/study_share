import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:app_study_share/features/study_groups/domain/repositories/study_group_repository.dart';

/// Student-facing study group use cases. Client-side checks give fast feedback
/// only; the Cloud Functions re-validate everything inside transactions.
abstract class StudyGroupUseCase {
  Future<List<StudyGroup>> getStudentGroups({required String studentId});

  Future<StudyGroup?> getGroupDetails({required String groupId});

  Future<String> createGroup({
    required String teacherId,
    required String subject,
    required String gradeLevel,
    required String slotId,
    required String notes,
    required int capacity,
    required int minStudents,
    required int maxStudents,
  });

  Future<void> joinGroup({required String groupId});

  Future<void> leaveGroup({required String groupId});
}

class StudyGroupUseCaseImpl implements StudyGroupUseCase {
  StudyGroupUseCaseImpl(this.repository);

  final StudyGroupRepository repository;

  @override
  Future<List<StudyGroup>> getStudentGroups({required String studentId}) =>
      repository.getStudentGroups(studentId: studentId);

  @override
  Future<StudyGroup?> getGroupDetails({required String groupId}) =>
      repository.getGroupDetails(groupId: groupId);

  @override
  Future<String> createGroup({
    required String teacherId,
    required String subject,
    required String gradeLevel,
    required String slotId,
    required String notes,
    required int capacity,
    required int minStudents,
    required int maxStudents,
  }) {
    if (subject.trim().isEmpty || slotId.isEmpty) {
      throw const ServerFailure(message: 'Missing subject or slot.', code: 'invalid-group');
    }
    if (capacity < minStudents || capacity > maxStudents || capacity < 2) {
      throw const ServerFailure(message: 'Invalid capacity.', code: 'invalid-capacity');
    }
    return repository.createGroup(
      teacherId: teacherId,
      subject: subject.trim(),
      gradeLevel: gradeLevel,
      slotId: slotId,
      notes: notes.trim(),
      capacity: capacity,
    );
  }

  @override
  Future<void> joinGroup({required String groupId}) =>
      repository.joinGroup(groupId: groupId);

  @override
  Future<void> leaveGroup({required String groupId}) =>
      repository.leaveGroup(groupId: groupId);
}
