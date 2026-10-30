import 'package:app_study_share/core/utils/guard.dart';
import 'package:app_study_share/features/study_groups/data/datasources/study_group_remote_source.dart';
import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:app_study_share/features/study_groups/domain/repositories/study_group_repository.dart';

class StudyGroupRepositoryImpl implements StudyGroupRepository {
  StudyGroupRepositoryImpl(this.remote);

  final StudyGroupRemoteSource remote;

  @override
  Future<List<StudyGroup>> getStudentGroups({required String studentId}) =>
      guardCall(() => remote.getStudentGroups(studentId: studentId));

  @override
  Future<StudyGroup?> getGroupDetails({required String groupId}) =>
      guardCall(() => remote.getGroupDetails(groupId: groupId));

  @override
  Future<String> createGroup({
    required String teacherId,
    required String subject,
    required String gradeLevel,
    required String slotId,
    required String notes,
    required int capacity,
  }) => guardCall(
    () => remote.createGroup({
      'teacherId': teacherId,
      'subject': subject,
      'gradeLevel': gradeLevel,
      'slotId': slotId,
      'notes': notes,
      'capacity': capacity,
    }),
  );

  @override
  Future<void> joinGroup({required String groupId}) =>
      guardCall(() => remote.joinGroup(groupId: groupId));

  @override
  Future<void> leaveGroup({required String groupId}) =>
      guardCall(() => remote.leaveGroup(groupId: groupId));
}
