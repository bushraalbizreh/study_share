import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:app_study_share/features/teacher_requests/domain/repositories/teacher_requests_repository.dart';

abstract class TeacherRequestsUseCase {
  Future<List<StudyGroup>> getRequests({required String teacherId});

  Future<StudyGroup?> getRequest({required String groupId});

  Future<void> accept({required String groupId});

  Future<void> reject({required String groupId});
}

class TeacherRequestsUseCaseImpl implements TeacherRequestsUseCase {
  TeacherRequestsUseCaseImpl(this.repository);

  final TeacherRequestsRepository repository;

  @override
  Future<List<StudyGroup>> getRequests({required String teacherId}) =>
      repository.getRequests(teacherId: teacherId);

  @override
  Future<StudyGroup?> getRequest({required String groupId}) =>
      repository.getRequest(groupId: groupId);

  @override
  Future<void> accept({required String groupId}) =>
      repository.decide(groupId: groupId, accept: true);

  @override
  Future<void> reject({required String groupId}) =>
      repository.decide(groupId: groupId, accept: false);
}
