import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/core/session/session.dart';
import 'package:app_study_share/features/student_home/domain/usecases/student_home_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'student_home_event.dart';
import 'student_home_state.dart';

class StudentHomeBloc extends Bloc<StudentHomeEvent, StudentHomeState> {
  StudentHomeBloc({required StudentHomeUseCase useCase, required Session session})
    : _useCase = useCase,
      _session = session,
      super(const StudentHomeInitial()) {
    on<StudentHomeRequested>(_onRequested);
  }

  final StudentHomeUseCase _useCase;
  final Session _session;

  Future<void> _onRequested(StudentHomeRequested e, Emitter<StudentHomeState> emit) async {
    emit(const StudentHomeLoading());
    try {
      emit(StudentHomeLoaded(await _useCase.execute(studentId: _session.user?.uid ?? '')));
    } on Failure catch (f) {
      emit(StudentHomeError(message: f.message, code: f.code));
    }
  }
}
