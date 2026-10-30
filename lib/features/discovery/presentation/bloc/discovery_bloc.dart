import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/features/discovery/domain/usecases/explore_teachers_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'discovery_event.dart';
import 'discovery_state.dart';

class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  DiscoveryBloc({required ExploreUseCase useCase})
    : _useCase = useCase,
      super(const DiscoveryInitial()) {
    on<ExploreRequested>(_onRequested);
    on<ExploreQueryChanged>(
      (e, emit) => _ifLoaded(emit, (s) => s.copyWith(query: e.query)),
    );
    on<ExploreTabChanged>((e, emit) => _ifLoaded(emit, (s) => s.copyWith(tab: e.tab)));
    on<ExploreLevelChanged>(
      (e, emit) => _ifLoaded(emit, (s) => s.copyWith(level: e.level)),
    );
  }

  final ExploreUseCase _useCase;

  void _ifLoaded(Emitter<DiscoveryState> emit, DiscoveryLoaded Function(DiscoveryLoaded) f) {
    final s = state;
    if (s is DiscoveryLoaded) emit(f(s));
  }

  Future<void> _onRequested(ExploreRequested e, Emitter<DiscoveryState> emit) async {
    final previous = state;
    emit(const DiscoveryLoading());
    try {
      final r = await _useCase.execute();
      emit(
        DiscoveryLoaded(
          allTeachers: r.teachers,
          allGroups: r.groups,
          query: previous is DiscoveryLoaded ? previous.query : '',
          tab: previous is DiscoveryLoaded ? previous.tab : 0,
          level: previous is DiscoveryLoaded ? previous.level : null,
        ),
      );
    } on Failure catch (f) {
      emit(DiscoveryError(message: f.message, code: f.code));
    }
  }
}
