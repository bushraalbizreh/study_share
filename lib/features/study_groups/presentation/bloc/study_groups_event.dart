import 'package:equatable/equatable.dart';

sealed class StudyGroupsEvent extends Equatable {
  const StudyGroupsEvent();

  @override
  List<Object?> get props => [];
}

class MyGroupsRequested extends StudyGroupsEvent {
  const MyGroupsRequested();
}

class GroupDetailsRequested extends StudyGroupsEvent {
  const GroupDetailsRequested(this.groupId);

  final String groupId;

  @override
  List<Object?> get props => [groupId];
}

class StudyGroupCreated extends StudyGroupsEvent {
  const StudyGroupCreated({
    required this.teacherId,
    required this.subject,
    required this.gradeLevel,
    required this.slotId,
    required this.notes,
    required this.capacity,
    required this.minStudents,
    required this.maxStudents,
  });

  final String teacherId;
  final String subject;
  final String gradeLevel;
  final String slotId;
  final String notes;
  final int capacity;
  final int minStudents;
  final int maxStudents;

  @override
  List<Object?> get props => [teacherId, subject, gradeLevel, slotId, notes, capacity];
}

class StudyGroupJoined extends StudyGroupsEvent {
  const StudyGroupJoined(this.groupId);

  final String groupId;

  @override
  List<Object?> get props => [groupId];
}

class StudyGroupLeft extends StudyGroupsEvent {
  const StudyGroupLeft(this.groupId);

  final String groupId;

  @override
  List<Object?> get props => [groupId];
}
