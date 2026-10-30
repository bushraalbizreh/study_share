import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';

abstract class TeacherRequestsRepository {
  /// Groups assigned to the teacher in `Pending` or `Accepted` status.
  Future<List<StudyGroup>> getRequests({required String teacherId});

  Future<StudyGroup?> getRequest({required String groupId});

  /// Accepts or rejects a `Pending` group through a trusted Cloud Function.
  Future<void> decide({required String groupId, required bool accept});
}
