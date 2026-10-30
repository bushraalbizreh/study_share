import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/features/teacher_profile/domain/usecases/get_teacher_profile_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'teacher_profile_event.dart';
import 'teacher_profile_state.dart';

class TeacherProfileBloc extends Bloc<TeacherProfileEvent, TeacherProfileState> {
  TeacherProfileBloc({required GetTeacherProfileUseCase useCase})
    : _useCase = useCase,
      super(const TeacherProfileInitial()) {
    on<TeacherProfileRequested>(_onRequested);
  }

  final GetTeacherProfileUseCase _useCase;

  Future<void> _onRequested(
    TeacherProfileRequested e,
    Emitter<TeacherProfileState> emit,
  ) async {
    emit(const TeacherProfileLoading());
    try {
      final details = await _useCase.execute(e.teacherId);
      emit(details == null ? const TeacherProfileNotFound() : TeacherProfileLoaded(details));
    } on Failure catch (f) {
      emit(TeacherProfileError(message: f.message, code: f.code));
    }
  }
}
