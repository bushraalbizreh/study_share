import 'package:app_study_share/features/teacher_profile/domain/usecases/get_teacher_profile_usecase.dart';
import 'package:equatable/equatable.dart';

sealed class TeacherProfileState extends Equatable {
  const TeacherProfileState();

  @override
  List<Object?> get props => [];
}

class TeacherProfileInitial extends TeacherProfileState {
  const TeacherProfileInitial();
}

class TeacherProfileLoading extends TeacherProfileState {
  const TeacherProfileLoading();
}

class TeacherProfileLoaded extends TeacherProfileState {
  const TeacherProfileLoaded(this.details);

  final TeacherProfileDetails details;

  @override
  List<Object?> get props => [details.profile, details.slots];
}

class TeacherProfileNotFound extends TeacherProfileState {
  const TeacherProfileNotFound();
}

class TeacherProfileError extends TeacherProfileState {
  const TeacherProfileError({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
