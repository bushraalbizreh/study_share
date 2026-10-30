import 'package:app_study_share/features/teacher_profile/domain/entities/teacher_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherProfileModel extends TeacherProfile {
  const TeacherProfileModel({
    required super.uid,
    required super.name,
    super.imageUrl,
    super.specialization,
    super.subjects,
    super.biography,
    super.prices,
    super.minStudents,
    super.maxStudents,
    super.isComplete,
  });

  factory TeacherProfileModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final rawPrices = (d['prices'] as Map?) ?? const {};
    return TeacherProfileModel(
      uid: doc.id,
      name: d['name'] as String? ?? '',
      imageUrl: d['imageUrl'] as String?,
      specialization: d['specialization'] as String? ?? '',
      subjects: ((d['subjects'] as List?) ?? const []).cast<String>(),
      biography: d['biography'] as String? ?? '',
      prices: rawPrices.map((k, v) => MapEntry(k as String, (v as num).toInt())),
      minStudents: (d['minStudents'] as num?)?.toInt() ?? 2,
      maxStudents: (d['maxStudents'] as num?)?.toInt() ?? 6,
      isComplete: d['isComplete'] as bool? ?? false,
    );
  }

  /// Fields a teacher may write. `imageUrl` is intentionally absent: it is
  /// only changed by the trusted profile-image Cloud Functions.
  static Map<String, dynamic> toWriteMap({
    required String name,
    required String specialization,
    required List<String> subjects,
    required String biography,
    required Map<String, int> prices,
    required int minStudents,
    required int maxStudents,
  }) {
    final complete = specialization.trim().isNotEmpty &&
        subjects.isNotEmpty &&
        prices.values.any((p) => p > 0);
    return {
      'name': name,
      'specialization': specialization,
      'subjects': subjects,
      'biography': biography,
      'prices': prices,
      'minStudents': minStudents,
      'maxStudents': maxStudents,
      'isComplete': complete,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
