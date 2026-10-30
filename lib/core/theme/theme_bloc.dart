import 'package:app_study_share/core/storage/local_store.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class ThemeAppStarted extends ThemeEvent {
  const ThemeAppStarted();
}

class ThemeModeChanged extends ThemeEvent {
  const ThemeModeChanged(this.mode);

  final ThemeMode mode;

  @override
  List<Object?> get props => [mode];
}

sealed class ThemeState extends Equatable {
  const ThemeState();

  @override
  List<Object?> get props => [];
}

class ThemeInitial extends ThemeState {
  const ThemeInitial();
}

class ThemeLoaded extends ThemeState {
  const ThemeLoaded(this.mode);

  final ThemeMode mode;

  @override
  List<Object?> get props => [mode];
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc({required LocalStore store})
    : _store = store,
      super(const ThemeInitial()) {
    on<ThemeAppStarted>(_onStarted);
    on<ThemeModeChanged>(_onChanged);
  }

  static const storageKey = 'theme_mode';
  final LocalStore _store;

  void _onStarted(ThemeAppStarted event, Emitter<ThemeState> emit) {
    final saved = _store.getString(storageKey);
    emit(
      ThemeLoaded(
        ThemeMode.values.firstWhere(
          (m) => m.name == saved,
          orElse: () => ThemeMode.system,
        ),
      ),
    );
  }

  Future<void> _onChanged(
    ThemeModeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    await _store.setString(storageKey, event.mode.name);
    emit(ThemeLoaded(event.mode));
  }
}
