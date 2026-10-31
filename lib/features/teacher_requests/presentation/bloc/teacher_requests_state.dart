import 'package:app_study_share/core/utils/firestore_paths.dart';
import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:equatable/equatable.dart';

sealed class TeacherRequestsState extends Equatable {
  const TeacherRequestsState();

  @override
  List<Object?> get props => [];
}

class TeacherRequestsInitial extends TeacherRequestsState {
  const TeacherRequestsInitial();
}

class TeacherRequestsLoading extends TeacherRequestsState {
  const TeacherRequestsLoading();
}

class TeacherRequestsLoaded extends TeacherRequestsState {
  const TeacherRequestsLoaded(this.requests);

  final List<StudyGroup> requests;

  List<StudyGroup> get pending =>
      requests.where((g) => g.status == GroupStatus.pending).toList();
  List<StudyGroup> get accepted =>
      requests.where((g) => g.status == GroupStatus.accepted).toList();

  @override
  List<Object?> get props => [requests];
}

class RequestDetailsLoaded extends TeacherRequestsState {
  const RequestDetailsLoaded(this.group);

  final StudyGroup? group;

  @override
  List<Object?> get props => [group];
}


class RequestDecisionSucceeded extends TeacherRequestsState {
  const RequestDecisionSucceeded({required this.accepted});

  final bool accepted;

  @override
  List<Object?> get props => [accepted];
}

class RequestDecisionFailed extends TeacherRequestsState {
  const RequestDecisionFailed({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

class TeacherRequestsError extends TeacherRequestsState {
  const TeacherRequestsError({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
