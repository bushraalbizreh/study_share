import 'package:equatable/equatable.dart';

sealed class TeacherRequestsEvent extends Equatable {
  const TeacherRequestsEvent();

  @override
  List<Object?> get props => [];
}

class RequestsRequested extends TeacherRequestsEvent {
  const RequestsRequested();
}

class RequestDetailsRequested extends TeacherRequestsEvent {
  const RequestDetailsRequested(this.groupId);

  final String groupId;

  @override
  List<Object?> get props => [groupId];
}

class RequestAccepted extends TeacherRequestsEvent {
  const RequestAccepted(this.groupId);

  final String groupId;

  @override
  List<Object?> get props => [groupId];
}

class RequestRejected extends TeacherRequestsEvent {
  const RequestRejected(this.groupId);

  final String groupId;

  @override
  List<Object?> get props => [groupId];
}
