import 'package:equatable/equatable.dart';

sealed class TeacherProfileEvent extends Equatable {
  const TeacherProfileEvent();

  @override
  List<Object?> get props => [];
}

class TeacherProfileRequested extends TeacherProfileEvent {
  const TeacherProfileRequested(this.teacherId);

  final String teacherId;

  @override
  List<Object?> get props => [teacherId];
}
