import 'package:app_study_share/features/auth/domain/entities/user.dart';

class Session {
  User? user;

  String? get role => user?.role;
  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';
}
