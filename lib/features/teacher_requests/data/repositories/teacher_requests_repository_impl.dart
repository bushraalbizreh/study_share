import 'package:app_study_share/core/utils/guard.dart';
import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:app_study_share/features/teacher_requests/data/datasources/teacher_requests_remote_source.dart';
import 'package:app_study_share/features/teacher_requests/domain/repositories/teacher_requests_repository.dart';

class TeacherRequestsRepositoryImpl implements TeacherRequestsRepository {
  TeacherRequestsRepositoryImpl(this.remote);

  final TeacherRequestsRemoteSource remote;

  @override
  Future<List<StudyGroup>> getRequests({required String teacherId}) =>
      guardCall(() => remote.getRequests(teacherId: teacherId));

  @override
  Future<StudyGroup?> getRequest({required String groupId}) =>
      guardCall(() => remote.getRequest(groupId: groupId));

  @override
  Future<void> decide({required String groupId, required bool accept}) =>
      guardCall(() => remote.decide(groupId: groupId, accept: accept));
}

