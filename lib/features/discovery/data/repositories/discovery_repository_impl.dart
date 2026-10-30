import 'package:app_study_share/core/utils/guard.dart';
import 'package:app_study_share/features/discovery/data/datasources/discovery_remote_source.dart';
import 'package:app_study_share/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:app_study_share/features/teacher_profile/domain/entities/teacher_profile.dart';

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  DiscoveryRepositoryImpl(this.remote);

  final DiscoveryRemoteSource remote;

  @override
  Future<List<TeacherProfile>> exploreTeachers() => guardCall(remote.exploreTeachers);

  @override
  Future<List<StudyGroup>> exploreOpenGroups() => guardCall(remote.exploreOpenGroups);
}
