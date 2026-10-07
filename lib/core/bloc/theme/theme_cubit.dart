// File: theme_cubit.dart
// Global state management untuk theme mode (light/dark)

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Cubit untuk manage theme mode (light/dark) globally
/// 
/// Responsibilities:
/// - Load theme preference saat app startup
/// - Toggle theme mode (light ↔ dark)
/// - Persist theme preference ke Hive
/// - Emit ThemeMode state untuk rebuild MaterialApp dengan theme baru
class ThemeCubit extends Cubit<ThemeMode> {
  // Nama box Hive untuk store preferences
  // Reuse box yang sama dengan LanguageCubit
  static const String _boxName = 'preferences_box';
  
  // Key untuk menyimpan theme mode
  static const String _themeModeKey = 'theme_mode';
  
  // Default theme jika tidak ada preference
  // Default = light mode
  static const ThemeMode _defaultThemeMode = ThemeMode.light;

  // Reference ke Hive box (lazy initialized)
  Box<dynamic>? _preferencesBox;

  /// Helper untuk memastikan Hive box sudah terbuka sebelum diakses
  Future<Box<dynamic>> _getBox() async {
    if (_preferencesBox != null && _preferencesBox!.isOpen) {
      return _preferencesBox!;
    }
    _preferencesBox = await Hive.openBox(_boxName);
    return _preferencesBox!;
  }

  /// Constructor — initialize dengan default ThemeMode.light
  /// 
  /// Emit ThemeMode.light sebagai initial state
  /// loadTheme() akan dipanggil di main() untuk load preference
  ThemeCubit() : super(ThemeMode.light);

  /// Initialize DAO — buka Hive box preferences
  /// 
  /// Harus dipanggil 1x di main() sebelum app startup
  /// Throws: Exception jika gagal buka box
  Future<void> initialize() async {
    try {
      // Buka box untuk preferences (non-encrypted)
      // Theme preference tidak sensitive data, boleh plain text
      // Box ini shared dengan LanguageCubit untuk efficiency
      await _getBox();
    } catch (e) {
      throw Exception('Failed to initialize ThemeCubit: $e');
    }
  }

  /// Load theme preference saat app startup
  /// 
  /// Dipanggil di main() sebelum app dijalankan
  /// Jika ada saved preference, load itu
  /// Jika tidak ada, use default (ThemeMode.light)
  Future<void> loadTheme() async {
    try {
      // Get theme mode string dari Hive preferences
      // String format: 'light', 'dark', 'system'
      final box = await _getBox();
      final themeModeString = box.get(
        _themeModeKey,
        defaultValue: _defaultThemeMode.toString(), // Default ke 'ThemeMode.light'
      );

      // Convert string ke ThemeMode enum
      // 'ThemeMode.light' → ThemeMode.light
      // 'ThemeMode.dark' → ThemeMode.dark
      // 'ThemeMode.system' → ThemeMode.system (follow OS theme)
      final themeMode = _parseThemeMode(themeModeString as String);

      // Emit ThemeMode yang di-load
      // MaterialApp akan auto-rebuild dengan theme baru
      emit(themeMode);
    } catch (e) {
      // Error saat load preference — fallback ke default
      debugPrint('Error loading theme: $e');
      emit(_defaultThemeMode);
    }
  }

  /// Toggle theme mode (light ↔ dark)
  /// 
  /// Jika current = light, switch ke dark
  /// Jika current = dark, switch ke light
  /// Jika current = system, switch ke light (safe default)
  /// 
  /// Disimpan ke Hive dan emit ThemeMode baru
  Future<void> toggleTheme() async {
    try {
      // Determine new theme mode berdasarkan current state
      // Toggle logic: light → dark, dark → light
      ThemeMode newThemeMode;
      if (state == ThemeMode.light) {
        newThemeMode = ThemeMode.dark; // Light → Dark
      } else {
        newThemeMode = ThemeMode.light; // Dark/System → Light
      }

      // Simpan theme preference ke Hive storage
      // Format: 'ThemeMode.light' atau 'ThemeMode.dark'
      final box = await _getBox();
      await box.put(_themeModeKey, newThemeMode.toString());

      // Emit ThemeMode baru
      // MaterialApp akan auto-rebuild dengan theme baru
      // Semua widgets yang listen ke theme_cubit akan rebuild
      emit(newThemeMode);
    } catch (e) {
      throw Exception('Failed to toggle theme: $e');
    }
  }

  /// Set theme mode explicitly (light/dark/system)
  /// 
  /// [themeMode]: ThemeMode enum (light, dark, atau system)
  /// 
  /// Disimpan ke Hive dan emit ThemeMode baru
  /// Useful untuk settings page dengan dropdown theme selector
  Future<void> setThemeMode(ThemeMode themeMode) async {
    try {
      // Simpan theme preference ke Hive storage
      final box = await _getBox();
      await box.put(_themeModeKey, themeMode.toString());

      // Emit ThemeMode baru
      emit(themeMode);
    } catch (e) {
      throw Exception('Failed to set theme mode: $e');
    }
  }

  /// Check apakah current theme light mode
  /// 
  /// Returns: true jika current theme = light, false jika bukan
  bool isLightMode() {
    return state == ThemeMode.light;
  }

  /// Check apakah current theme dark mode
  /// 
  /// Returns: true jika current theme = dark, false jika bukan
  bool isDarkMode() {
    return state == ThemeMode.dark;
  }

  /// Close Hive box — cleanup resources
  /// 
  /// Panggil saat app shutdown
  @override
  Future<void> close() async {
    try {
      if (_preferencesBox != null && _preferencesBox!.isOpen) {
        await _preferencesBox!.close();
      }
    } catch (e) {
      // ignore
    }
    return super.close();
  }

  // ==================== PRIVATE HELPERS ====================

  /// Parse string 'ThemeMode.light' ke ThemeMode enum
  /// 
  /// [themeModeString]: String format 'ThemeMode.light'
  /// Returns: ThemeMode enum
  ThemeMode _parseThemeMode(String themeModeString) {
    // Extract enum value dari string 'ThemeMode.light' → 'light'
    // Split by '.' dan ambil bagian terakhir
    final modeString = themeModeString.split('.').last;

    // Match string dengan enum values
    switch (modeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system; // Follow OS theme
      default:
        // Unknown value — fallback ke default
        return _defaultThemeMode;
    }
  }
}

