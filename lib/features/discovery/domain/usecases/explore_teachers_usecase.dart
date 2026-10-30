import 'package:app_study_share/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:app_study_share/features/teacher_profile/domain/entities/teacher_profile.dart';

class ExploreResult {
  const ExploreResult({required this.teachers, required this.groups});

  final List<TeacherProfile> teachers;
  final List<StudyGroup> groups;
}

/// Loads teachers and Open groups for the Explore and Home screens.
abstract class ExploreUseCase {
  Future<ExploreResult> execute();
}

class ExploreUseCaseImpl implements ExploreUseCase {
  ExploreUseCaseImpl(this.repository);

  final DiscoveryRepository repository;

  @override
  Future<ExploreResult> execute() async {
    final results = await Future.wait<Object>([
      repository.exploreTeachers(),
      repository.exploreOpenGroups(),
    ]);
    return ExploreResult(
      teachers: results[0] as List<TeacherProfile>,
      groups: results[1] as List<StudyGroup>,
    );
  }
}
