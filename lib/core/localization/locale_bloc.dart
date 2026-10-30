import 'package:app_study_share/core/storage/local_store.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class LocaleEvent extends Equatable {
  const LocaleEvent();

  @override
  List<Object?> get props => [];
}

class LocaleAppStarted extends LocaleEvent {
  const LocaleAppStarted();
}

class LocaleChanged extends LocaleEvent {
  const LocaleChanged(this.locale);

  final Locale locale;

  @override
  List<Object?> get props => [locale];
}

sealed class LocaleState extends Equatable {
  const LocaleState();

  @override
  List<Object?> get props => [];
}

class LocaleInitial extends LocaleState {
  const LocaleInitial();
}

class LocaleLoaded extends LocaleState {
  const LocaleLoaded(this.locale);

  final Locale locale;

  @override
  List<Object?> get props => [locale];
}


class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  LocaleBloc({required LocalStore store})
    : _store = store,
      super(const LocaleInitial()) {
    on<LocaleAppStarted>(_onStarted);
    on<LocaleChanged>(_onChanged);
  }

  static const storageKey = 'language_code';
  final LocalStore _store;

  void _onStarted(LocaleAppStarted event, Emitter<LocaleState> emit) {
    final code = _store.getString(storageKey);
    emit(LocaleLoaded(Locale(code == 'ar' ? 'ar' : 'en')));
  }

  Future<void> _onChanged(
    LocaleChanged event,
    Emitter<LocaleState> emit,
  ) async {
    await _store.setString(storageKey, event.locale.languageCode);
    emit(LocaleLoaded(event.locale));
  }
}
