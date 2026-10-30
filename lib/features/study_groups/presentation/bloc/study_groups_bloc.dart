import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/core/session/session.dart';
import 'package:app_study_share/features/study_groups/domain/usecases/study_group_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'study_groups_event.dart';
import 'study_groups_state.dart';

class StudyGroupsBloc extends Bloc<StudyGroupsEvent, StudyGroupsState> {
  StudyGroupsBloc({required StudyGroupUseCase useCase, required Session session})
    : _useCase = useCase,
      _session = session,
      super(const StudyGroupsInitial()) {
    on<MyGroupsRequested>(_onMyGroups);
    on<GroupDetailsRequested>(_onDetails);
    on<StudyGroupCreated>(_onCreate);
    on<StudyGroupJoined>(_onJoin);
    on<StudyGroupLeft>(_onLeave);
  }

  final StudyGroupUseCase _useCase;
  final Session _session;

  Future<void> _onMyGroups(MyGroupsRequested e, Emitter<StudyGroupsState> emit) async {
    emit(const StudyGroupsLoading());
    try {
      final uid = _session.user?.uid ?? '';
      emit(MyGroupsLoaded(await _useCase.getStudentGroups(studentId: uid)));
    } on Failure catch (f) {
      emit(StudyGroupsError(message: f.message, code: f.code));
    }
  }

  Future<void> _onDetails(GroupDetailsRequested e, Emitter<StudyGroupsState> emit) async {
    emit(const StudyGroupsLoading());
    try {
      emit(GroupDetailsLoaded(await _useCase.getGroupDetails(groupId: e.groupId)));
    } on Failure catch (f) {
      emit(StudyGroupsError(message: f.message, code: f.code));
    }
  }

  Future<void> _onCreate(StudyGroupCreated e, Emitter<StudyGroupsState> emit) async {
    emit(const StudyGroupsLoading());
    try {
      final id = await _useCase.createGroup(
        teacherId: e.teacherId,
        subject: e.subject,
        gradeLevel: e.gradeLevel,
        slotId: e.slotId,
        notes: e.notes,
        capacity: e.capacity,
        minStudents: e.minStudents,
        maxStudents: e.maxStudents,
      );
      emit(StudyGroupActionSucceeded('created', groupId: id));
    } on Failure catch (f) {
      emit(StudyGroupActionFailed(message: f.message, code: f.code));
    }
  }

  Future<void> _onJoin(StudyGroupJoined e, Emitter<StudyGroupsState> emit) async {
    try {
      await _useCase.joinGroup(groupId: e.groupId);
      emit(StudyGroupActionSucceeded('joined', groupId: e.groupId));
    } on Failure catch (f) {
      emit(StudyGroupActionFailed(message: f.message, code: f.code));
    }
    add(GroupDetailsRequested(e.groupId));
  }

  Future<void> _onLeave(StudyGroupLeft e, Emitter<StudyGroupsState> emit) async {
    try {
      await _useCase.leaveGroup(groupId: e.groupId);
      emit(StudyGroupActionSucceeded('left', groupId: e.groupId));
    } on Failure catch (f) {
      emit(StudyGroupActionFailed(message: f.message, code: f.code));
      add(GroupDetailsRequested(e.groupId));
    }
  }
}
