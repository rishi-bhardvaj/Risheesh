import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeNotifier(this._prefs) : super(_loadThemeMode(_prefs));

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final savedMode = prefs.getString(AppConstants.keyThemeMode);
    switch (savedMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    String modeString = 'system';
    if (mode == ThemeMode.light) modeString = 'light';
    if (mode == ThemeMode.dark) modeString = 'dark';
    await _prefs.setString(AppConstants.keyThemeMode, modeString);
  }
}

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

