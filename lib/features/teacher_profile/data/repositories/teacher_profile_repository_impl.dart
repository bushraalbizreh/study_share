import 'package:app_study_share/core/utils/guard.dart';
import 'package:app_study_share/features/teacher_profile/data/datasources/teacher_profile_remote_source.dart';
import 'package:app_study_share/features/teacher_profile/domain/entities/teacher_profile.dart';
import 'package:app_study_share/features/teacher_profile/domain/repositories/teacher_profile_repository.dart';

class TeacherProfileRepositoryImpl implements TeacherProfileRepository {
  TeacherProfileRepositoryImpl(this.remote);

  final TeacherProfileRemoteSource remote;

  @override
  Future<TeacherProfile?> getTeacherProfile({required String teacherId}) =>
      guardCall(() => remote.getTeacherProfile(teacherId: teacherId));
}
