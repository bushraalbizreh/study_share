import 'package:app_study_share/features/teacher_profile/domain/entities/teacher_profile.dart';

abstract class TeacherProfileRepository {
  Future<TeacherProfile?> getTeacherProfile({required String teacherId});
}
