import 'package:app_study_share/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:app_study_share/features/study_groups/domain/repositories/study_group_repository.dart';
import 'package:app_study_share/features/teacher_profile/domain/entities/teacher_profile.dart';

class StudentHomeData {
  const StudentHomeData({
    required this.myGroups,
    required this.teachers,
    required this.openGroups,
  });

  final List<StudyGroup> myGroups;
  final List<TeacherProfile> teachers;
  final List<StudyGroup> openGroups;

  /// The student's soonest upcoming Accepted group, else soonest Pending.
  StudyGroup? get next {
    final now = DateTime.now();
    final upcoming = myGroups.where((g) => g.startAt.isAfter(now)).toList();
    for (final status in ['Accepted', 'Pending']) {
      final m = upcoming.where((g) => g.status == status);
      if (m.isNotEmpty) return m.first;
    }
    return null;
  }
}

abstract class StudentHomeUseCase {
  Future<StudentHomeData> execute({required String studentId});
}

class StudentHomeUseCaseImpl implements StudentHomeUseCase {
  StudentHomeUseCaseImpl(this.groups, this.discovery);

  final StudyGroupRepository groups;
  final DiscoveryRepository discovery;

  @override
  Future<StudentHomeData> execute({required String studentId}) async {
    final results = await Future.wait<Object>([
      groups.getStudentGroups(studentId: studentId),
      discovery.exploreTeachers(),
      discovery.exploreOpenGroups(),
    ]);
    final open = (results[2] as List<StudyGroup>)
        .where((g) => !g.hasMember(studentId))
        .toList();
    return StudentHomeData(
      myGroups: results[0] as List<StudyGroup>,
      teachers: (results[1] as List<TeacherProfile>).take(5).toList(),
      openGroups: open.take(5).toList(),
    );
  }
}
