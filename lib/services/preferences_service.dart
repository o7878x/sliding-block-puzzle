import 'package:shared_preferences/shared_preferences.dart';

/// Caches user preferences via [SharedPreferences] (localStorage on web).
class PreferencesService {
  static const String _gridSizeKey = 'grid_size';
  static const int _defaultGridSize = 3;

  /// Reads the cached grid size, defaulting to 3.
  static Future<int> getGridSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_gridSizeKey) ?? _defaultGridSize;
  }

  /// Persists the chosen grid size.
  static Future<void> setGridSize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_gridSizeKey, size);
  }
}
