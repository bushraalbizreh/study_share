import 'package:app_study_share/features/student_home/domain/usecases/student_home_usecase.dart';
import 'package:equatable/equatable.dart';

sealed class StudentHomeState extends Equatable {
  const StudentHomeState();

  @override
  List<Object?> get props => [];
}

class StudentHomeInitial extends StudentHomeState {
  const StudentHomeInitial();
}

class StudentHomeLoading extends StudentHomeState {
  const StudentHomeLoading();
}

class StudentHomeLoaded extends StudentHomeState {
  const StudentHomeLoaded(this.data);

  final StudentHomeData data;

  @override
  List<Object?> get props => [data.myGroups, data.teachers, data.openGroups];
}

class StudentHomeError extends StudentHomeState {
  const StudentHomeError({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
