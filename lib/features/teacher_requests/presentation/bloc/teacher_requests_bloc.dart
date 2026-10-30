import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/core/session/session.dart';
import 'package:app_study_share/features/teacher_requests/domain/usecases/teacher_requests_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'teacher_requests_event.dart';
import 'teacher_requests_state.dart';

class TeacherRequestsBloc extends Bloc<TeacherRequestsEvent, TeacherRequestsState> {
  TeacherRequestsBloc({required TeacherRequestsUseCase useCase, required Session session})
    : _useCase = useCase,
      _session = session,
      super(const TeacherRequestsInitial()) {
    on<RequestsRequested>(_onRequests);
    on<RequestDetailsRequested>(_onDetails);
    on<RequestAccepted>((e, emit) => _decide(e.groupId, true, emit));
    on<RequestRejected>((e, emit) => _decide(e.groupId, false, emit));
  }

  final TeacherRequestsUseCase _useCase;
  final Session _session;

  Future<void> _onRequests(RequestsRequested e, Emitter<TeacherRequestsState> emit) async {
    emit(const TeacherRequestsLoading());
    try {
      emit(
        TeacherRequestsLoaded(
          await _useCase.getRequests(teacherId: _session.user?.uid ?? ''),
        ),
      );
    } on Failure catch (f) {
      emit(TeacherRequestsError(message: f.message, code: f.code));
    }
  }

  Future<void> _onDetails(
    RequestDetailsRequested e,
    Emitter<TeacherRequestsState> emit,
  ) async {
    emit(const TeacherRequestsLoading());
    try {
      emit(RequestDetailsLoaded(await _useCase.getRequest(groupId: e.groupId)));
    } on Failure catch (f) {
      emit(TeacherRequestsError(message: f.message, code: f.code));
    }
  }

  Future<void> _decide(String groupId, bool accept, Emitter<TeacherRequestsState> emit) async {
    try {
      accept
          ? await _useCase.accept(groupId: groupId)
          : await _useCase.reject(groupId: groupId);
      emit(RequestDecisionSucceeded(accepted: accept));
    } on Failure catch (f) {
      emit(RequestDecisionFailed(message: f.message, code: f.code));
      add(RequestDetailsRequested(groupId));
    }
  }
}
