import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/core/session/session.dart';
import 'package:app_study_share/features/availability/domain/entities/availability_slot.dart';
import 'package:app_study_share/features/availability/domain/usecases/availability_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'availability_event.dart';
import 'availability_state.dart';

class AvailabilityBloc extends Bloc<AvailabilityEvent, AvailabilityState> {
  AvailabilityBloc({required AvailabilityUseCase useCase, required Session session})
    : _useCase = useCase,
      _session = session,
      super(const AvailabilityInitial()) {
    on<AvailabilityRequested>(_onRequested);
    on<AvailabilitySlotCreated>(_onCreated);
    on<AvailabilitySlotDeleted>(_onDeleted);
  }

  final AvailabilityUseCase _useCase;
  final Session _session;

  String get _uid => _session.user?.uid ?? '';

  List<AvailabilitySlot> get _current {
    final s = state;
    return s is AvailabilityLoaded ? s.slots : const [];
  }

  Future<void> _onRequested(AvailabilityRequested e, Emitter<AvailabilityState> emit) async {
    emit(const AvailabilityLoading());
    try {
      emit(AvailabilityLoaded(await _useCase.getTeacherSlots(teacherId: _uid)));
    } on Failure catch (f) {
      emit(AvailabilityError(message: f.message, code: f.code));
    }
  }

  Future<void> _onCreated(AvailabilitySlotCreated e, Emitter<AvailabilityState> emit) async {
    final before = _current;
    try {
      await _useCase.createSlot(
        teacherId: _uid,
        startAt: e.startAt,
        durationMinutes: e.durationMinutes,
      );
      emit(AvailabilityActionDone(await _useCase.getTeacherSlots(teacherId: _uid), 'created'));
    } on Failure catch (f) {
      emit(AvailabilityActionFailed(before, message: f.message, code: f.code));
    }
  }

  Future<void> _onDeleted(AvailabilitySlotDeleted e, Emitter<AvailabilityState> emit) async {
    final before = _current;
    try {
      await _useCase.deleteSlot(slotId: e.slotId);
      emit(AvailabilityActionDone(await _useCase.getTeacherSlots(teacherId: _uid), 'deleted'));
    } on Failure catch (f) {
      emit(AvailabilityActionFailed(before, message: f.message, code: f.code));
    }
  }
}
