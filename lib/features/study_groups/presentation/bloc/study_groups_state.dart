import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:equatable/equatable.dart';

sealed class StudyGroupsState extends Equatable {
  const StudyGroupsState();

  @override
  List<Object?> get props => [];
}

class StudyGroupsInitial extends StudyGroupsState {
  const StudyGroupsInitial();
}

class StudyGroupsLoading extends StudyGroupsState {
  const StudyGroupsLoading();
}

class MyGroupsLoaded extends StudyGroupsState {
  const MyGroupsLoaded(this.groups);

  final List<StudyGroup> groups;

  @override
  List<Object?> get props => [groups];
}

/// `group == null` means it no longer exists (e.g. an emptied Open group).
class GroupDetailsLoaded extends StudyGroupsState {
  const GroupDetailsLoaded(this.group);

  final StudyGroup? group;

  @override
  List<Object?> get props => [group];
}

/// One-time success feedback for BlocListener (`created`, `joined`, `left`).
class StudyGroupActionSucceeded extends StudyGroupsState {
  const StudyGroupActionSucceeded(this.action, {this.groupId});

  final String action;
  final String? groupId;

  @override
  List<Object?> get props => [action, groupId];
}

/// One-time error feedback for BlocListener.
class StudyGroupActionFailed extends StudyGroupsState {
  const StudyGroupActionFailed({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

class StudyGroupsError extends StudyGroupsState {
  const StudyGroupsError({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
