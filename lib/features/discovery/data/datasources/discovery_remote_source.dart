import 'package:app_study_share/core/utils/firestore_paths.dart';
import 'package:app_study_share/features/study_groups/data/models/study_group_model.dart';
import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:app_study_share/features/teacher_profile/data/models/teacher_profile_model.dart';
import 'package:app_study_share/features/teacher_profile/domain/entities/teacher_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class DiscoveryRemoteSource {
  Future<List<TeacherProfile>> exploreTeachers();

  Future<List<StudyGroup>> exploreOpenGroups();
}

class DiscoveryRemoteSourceImpl implements DiscoveryRemoteSource {
  DiscoveryRemoteSourceImpl({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<List<TeacherProfile>> exploreTeachers() async {
    final snap = await _db
        .collection(FirestorePaths.teacherProfiles)
        .where('isComplete', isEqualTo: true)
        .limit(100)
        .get();
    return snap.docs.map(TeacherProfileModel.fromDoc).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<List<StudyGroup>> exploreOpenGroups() async {
    final snap = await _db
        .collection(FirestorePaths.groups)
        .where('status', isEqualTo: GroupStatus.open)
        .limit(100)
        .get();
    final now = DateTime.now();
    return snap.docs.map(StudyGroupModel.fromDoc).where((g) => g.startAt.isAfter(now)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }
}
