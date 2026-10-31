import 'package:equatable/equatable.dart';

/// Public teacher profile (specialization, subjects, prices per stage).
class TeacherProfile extends Equatable {
  const TeacherProfile({
    required this.uid,
    required this.name,
    this.imageUrl,
    this.specialization = '',
    this.subjects = const [],
    this.biography = '',
    this.prices = const {},
    this.minStudents = 2,
    this.maxStudents = 6,
    this.isComplete = false,
  });

  final String uid;
  final String name;
  final String? imageUrl;
  final String specialization;
  final List<String> subjects;
  final String biography;

  final Map<String, int> prices;

  final int minStudents;
  final int maxStudents;
  final bool isComplete;

  int? priceFor(String level) => prices[level];

  List<String> get levels =>
      ['elementary', 'middle', 'high'].where((l) => (prices[l] ?? 0) > 0).toList();

  @override
  List<Object?> get props => [
    uid, name, imageUrl, specialization, subjects, biography, prices,
    minStudents, maxStudents, isComplete,
  ];
}
