import 'package:hive_flutter/hive_flutter.dart';

abstract class LocalStore {
  String? getString(String key);
  bool getBool(String key, {bool defaultValue = false});
  Future<void> setString(String key, String value);
  Future<void> setBool(String key, bool value);
}

/// Hive-backed [LocalStore].
class HiveLocalStore implements LocalStore {
  HiveLocalStore._(this._box);

  final Box<dynamic> _box;

  static Future<HiveLocalStore> open() async {
    await Hive.initFlutter();
    return HiveLocalStore._(await Hive.openBox<dynamic>('settings'));
  }

  @override
  String? getString(String key) => _box.get(key) as String?;

  @override
  bool getBool(String key, {bool defaultValue = false}) =>
      _box.get(key, defaultValue: defaultValue) as bool;

  @override
  Future<void> setString(String key, String value) => _box.put(key, value);

  @override
  Future<void> setBool(String key, bool value) => _box.put(key, value);
}
