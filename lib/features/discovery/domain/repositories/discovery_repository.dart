import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:app_study_share/features/teacher_profile/domain/entities/teacher_profile.dart';

abstract class DiscoveryRepository {
  /// Teachers with a completed profile.
  Future<List<TeacherProfile>> exploreTeachers();

  /// Study groups currently in `Open` status.
  Future<List<StudyGroup>> exploreOpenGroups();
}
