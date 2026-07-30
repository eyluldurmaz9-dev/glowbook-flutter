import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService(this._preferences);

  final SharedPreferences _preferences;

  bool getBool(String key, {bool defaultValue = false}) {
    return _preferences.getBool(key) ?? defaultValue;
  }

  Future<bool> setBool(String key, bool value) {
    return _preferences.setBool(key, value);
  }

  String? getString(String key) {
    return _preferences.getString(key);
  }

  Future<bool> setString(String key, String value) {
    return _preferences.setString(key, value);
  }

  Future<bool> remove(String key) {
    return _preferences.remove(key);
  }
}
