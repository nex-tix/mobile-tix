// File: language_cubit.dart
// Global state management untuk language/locale i18n

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Cubit untuk manage application language/locale globally
/// 
/// Responsibilities:
/// - Load language preference saat app startup
/// - Change language + persist ke Hive
/// - Emit locale state untuk rebuild UI dengan bahasa baru
/// - Support Indonesian (id) dan English (en)
class LanguageCubit extends Cubit<Locale> {
  // Nama box Hive untuk store preferences
  static const String _boxName = 'preferences_box';
  
  // Key untuk menyimpan language code
  static const String _languageKey = 'language_code';
  
  // Default language jika tidak ada preference
  static const String _defaultLanguage = 'id'; // Indonesian default

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

  /// Constructor — initialize dengan default locale Indonesian
  /// 
  /// Emit Locale('id') sebagai initial state
  /// loadLanguage() akan dipanggil di main() untuk load preference
  LanguageCubit() : super(const Locale('id'));

  /// Initialize DAO — buka Hive box preferences
  /// 
  /// Harus dipanggil 1x di main() sebelum app startup
  /// Throws: Exception jika gagal buka box
  Future<void> initialize() async {
    try {
      // Buka box untuk preferences (non-encrypted untuk language preference)
      // Language preference tidak sensitive data, boleh plain text
      await _getBox();
    } catch (e) {
      throw Exception('Failed to initialize LanguageCubit: $e');
    }
  }

  /// Load language preference saat app startup
  /// 
  /// Dipanggil di main() sebelum app dijalankan
  /// Jika ada saved preference, load itu
  /// Jika tidak ada, use default (Indonesian)
  Future<void> loadLanguage() async {
    try {
      // Get language code dari Hive preferences
      // Hive.get() return null jika key tidak ada
      final box = await _getBox();
      final languageCode = box.get(
        _languageKey,
        defaultValue: _defaultLanguage, // Default ke 'id' jika tidak ada
      );

      // Validasi: hanya 'id' dan 'en' yang didukung.
      // Nilai korup / tidak dikenal di storage fallback ke default,
      // supaya locale tidak pernah berisi kode bahasa asing.
      final code = languageCode as String;
      final safeCode =
          (code == 'id' || code == 'en') ? code : _defaultLanguage;

      // Emit Locale dengan language code yang di-load & sudah tervalidasi
      // Locale('id') = Indonesian, Locale('en') = English
      // Ini akan trigger MaterialApp rebuild dengan locale baru
      emit(Locale(safeCode));
    } catch (e) {
      // Error saat load preference — fallback ke default
      debugPrint('Error loading language: $e');
      emit(const Locale(_defaultLanguage));
    }
  }

  /// Change language dan persist ke storage
  /// 
  /// [languageCode]: Code bahasa ('id' untuk Indonesian, 'en' untuk English)
  /// 
  /// Disimpan ke Hive dan emit Locale baru
  /// Semua UI yang listen ke language_cubit akan rebuild dengan bahasa baru
  Future<void> changeLanguage(String languageCode) async {
    try {
      // Validate language code (hanya support 'id' dan 'en')
      // Jika code tidak valid, throw error
      if (languageCode != 'id' && languageCode != 'en') {
        throw Exception('Unsupported language code: $languageCode');
      }

      // Simpan language preference ke Hive storage
      // Ini persist ke disk, jadi next app startup akan load bahasa ini
      final box = await _getBox();
      await box.put(_languageKey, languageCode);

      // Emit Locale baru
      // MaterialApp akan auto-rebuild dengan locale baru
      // easy_localization plugin akan auto-switch translations
      emit(Locale(languageCode));
    } catch (e) {
      throw Exception('Failed to change language: $e');
    }
  }

  /// Get current language code
  /// 
  /// Returns: Language code string ('id' atau 'en')
  /// 
  /// Convenience method untuk akses language dari state
  String getCurrentLanguageCode() {
    // state.languageCode = property dari Locale class
    // Contoh: Locale('id').languageCode = 'id'
    return state.languageCode;
  }

  /// Check apakah current language Indonesian
  /// 
  /// Returns: true jika current language = 'id', false jika bukan
  bool isIndonesian() {
    return state.languageCode == 'id';
  }

  /// Check apakah current language English
  /// 
  /// Returns: true jika current language = 'en', false jika bukan
  bool isEnglish() {
    return state.languageCode == 'en';
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
}

