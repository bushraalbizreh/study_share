import 'package:app_study_share/features/profile/domain/entities/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileModel {
  /// Builds a [Profile] from the `users` doc and the optional teacher doc.
  static Profile fromDocs({
    required String uid,
    required String email,
    required Map<String, dynamic> user,
    Map<String, dynamic>? teacher,
  }) {
    final t = teacher ?? const <String, dynamic>{};
    final rawPrices = (t['prices'] as Map?) ?? const {};
    return Profile(
      uid: uid,
      email: email,
      name: user['name'] as String? ?? '',
      role: user['role'] == 'teacher' ? 'teacher' : 'student',
      imageUrl: user['imageUrl'] as String?,
      specialization: t['specialization'] as String? ?? '',
      subjects: ((t['subjects'] as List?) ?? const []).cast<String>(),
      biography: t['biography'] as String? ?? '',
      prices: rawPrices.map((k, v) => MapEntry(k as String, (v as num).toInt())),
      minStudents: (t['minStudents'] as num?)?.toInt() ?? 2,
      maxStudents: (t['maxStudents'] as num?)?.toInt() ?? 6,
    );
  }

  /// Fields a teacher may write. `imageUrl` is absent on purpose: only the
  /// trusted profile-image Cloud Functions change it.
  static Map<String, dynamic> teacherMap(Profile p) {
    final complete = p.specialization.trim().isNotEmpty &&
        p.subjects.isNotEmpty &&
        p.prices.values.any((v) => v > 0);
    return {
      'name': p.name,
      'specialization': p.specialization,
      'subjects': p.subjects,
      'biography': p.biography,
      'prices': p.prices,
      'minStudents': p.minStudents,
      'maxStudents': p.maxStudents,
      'isComplete': complete,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
