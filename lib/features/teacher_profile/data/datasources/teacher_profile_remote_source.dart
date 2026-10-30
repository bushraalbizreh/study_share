import 'package:app_study_share/core/utils/firestore_paths.dart';
import 'package:app_study_share/features/teacher_profile/data/models/teacher_profile_model.dart';
import 'package:app_study_share/features/teacher_profile/domain/entities/teacher_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class TeacherProfileRemoteSource {
  Future<TeacherProfile?> getTeacherProfile({required String teacherId});
}

class TeacherProfileRemoteSourceImpl implements TeacherProfileRemoteSource {
  TeacherProfileRemoteSourceImpl({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<TeacherProfile?> getTeacherProfile({required String teacherId}) async {
    final doc = await _db.collection(FirestorePaths.teacherProfiles).doc(teacherId).get();
    return doc.exists ? TeacherProfileModel.fromDoc(doc) : null;
  }
}
