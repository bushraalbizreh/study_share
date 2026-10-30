import 'package:equatable/equatable.dart';

/// Application user. `role` is `student` or `teacher` and is immutable after
/// registration (enforced by Firestore Security Rules).
class User extends Equatable {
  const User({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.imageUrl,
  });

  final String uid;
  final String email;
  final String name;
  final String role;
  final String? imageUrl;

  bool get isTeacher => role == 'teacher';

  @override
  List<Object?> get props => [uid, email, name, role, imageUrl];
}
