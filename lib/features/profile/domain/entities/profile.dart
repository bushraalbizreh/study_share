import 'package:equatable/equatable.dart';

/// A user's profile. Teacher-only fields are empty for students.
class Profile extends Equatable {
  const Profile({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.imageUrl,
    this.specialization = '',
    this.subjects = const [],
    this.biography = '',
    this.prices = const {},
    this.minStudents = 2,
    this.maxStudents = 6,
  });

  final String uid;
  final String email;
  final String name;
  final String role;
  final String? imageUrl;
  final String specialization;
  final List<String> subjects;
  final String biography;

  /// Price per student per session for `elementary` / `middle` / `high`.
  final Map<String, int> prices;

  /// Minimum / maximum students per study group (including the creator).
  final int minStudents;
  final int maxStudents;

  bool get isTeacher => role == 'teacher';

  Profile copyWith({
    String? name,
    String? imageUrl,
    String? specialization,
    List<String>? subjects,
    String? biography,
    Map<String, int>? prices,
    int? minStudents,
    int? maxStudents,
  }) => Profile(
    uid: uid,
    email: email,
    name: name ?? this.name,
    role: role,
    imageUrl: imageUrl ?? this.imageUrl,
    specialization: specialization ?? this.specialization,
    subjects: subjects ?? this.subjects,
    biography: biography ?? this.biography,
    prices: prices ?? this.prices,
    minStudents: minStudents ?? this.minStudents,
    maxStudents: maxStudents ?? this.maxStudents,
  );

  @override
  List<Object?> get props => [
    uid, email, name, role, imageUrl, specialization, subjects, biography,
    prices, minStudents, maxStudents,
  ];
}
