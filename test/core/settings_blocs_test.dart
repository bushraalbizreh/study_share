import 'package:app_study_share/core/localization/locale_bloc.dart';
import 'package:app_study_share/core/storage/local_store.dart';
import 'package:app_study_share/core/theme/theme_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements LocalStore {
  final Map<String, Object> data = {};

  @override
  bool getBool(String key, {bool defaultValue = false}) => (data[key] as bool?) ?? defaultValue;

  @override
  String? getString(String key) => data[key] as String?;

  @override
  Future<void> setBool(String key, bool value) async => data[key] = value;

  @override
  Future<void> setString(String key, String value) async => data[key] = value;
}

void main() {
  blocTest<LocaleBloc, LocaleState>(
    'restores the saved language',
    build: () => LocaleBloc(store: _MemoryStore()..data[LocaleBloc.storageKey] = 'ar'),
    act: (b) => b.add(const LocaleAppStarted()),
    expect: () => [const LocaleLoaded(Locale('ar'))],
  );

  test('changing language persists it', () async {
    final store = _MemoryStore();
    final bloc = LocaleBloc(store: store)..add(const LocaleChanged(Locale('ar')));
    await bloc.stream.firstWhere((s) => s is LocaleLoaded);
    expect(store.getString(LocaleBloc.storageKey), 'ar');
    await bloc.close();
  });

  blocTest<ThemeBloc, ThemeState>(
    'defaults to system and persists the chosen mode',
    build: () => ThemeBloc(store: _MemoryStore()),
    act: (b) => b
      ..add(const ThemeAppStarted())
      ..add(const ThemeModeChanged(ThemeMode.dark)),
    expect: () => [const ThemeLoaded(ThemeMode.system), const ThemeLoaded(ThemeMode.dark)],
  );
}
