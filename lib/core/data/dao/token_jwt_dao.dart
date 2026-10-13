// File: token_jwt_dao.dart
// Data Access Object untuk JWT token storage dengan encryption

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../config/env_config.dart';

/// DAO untuk menyimpan & mengambil JWT token dari Hive database
/// 
/// Features:
/// - Automatic encryption/decryption menggunakan AES-CBC
/// - Hanya 1 record: current token + metadata (expiry, issued_at)
/// - Singleton pattern — hanya 1 instance di seluruh app
class TokenJwtDAO {
  // Nama box Hive untuk menyimpan token
  // Box adalah container seperti table di SQL database
  static const String _boxName = 'token_box';
  
  // Key untuk menyimpan token data
  // Dalam box Hive, data disimpan dengan key-value pair
  static const String _tokenKey = 'jwt_token';

  // Key masa berlaku token (dari field expires_at balikan /login).
  // Dipakai saat aplikasi dibuka ulang: token yang sudah lewat masa berlaku
  // tidak perlu dipakai masuk lagi.
  static const String _expiryKey = 'jwt_expires_at';

  // Singleton instance — hanya 1 DAO untuk token
  static final TokenJwtDAO _instance = TokenJwtDAO._internal();
  
  // Factory constructor — return singleton instance
  factory TokenJwtDAO() => _instance;
  
  // Private internal constructor
  TokenJwtDAO._internal();

  // Reference ke Hive box
  Box<String>? _tokenBox;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize DAO — buka Hive box dengan encryption
  /// 
  /// Harus dipanggil 1x di main() sebelum app digunakan
  /// Throws: Exception jika gagal buka box
  Future<void> initialize() async {
    try {
      final keyString = EnvConfig.secretKey;
      final keyBytes = utf8.encode(keyString);
      final validKeyBytes = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        validKeyBytes[i] = i < keyBytes.length ? keyBytes[i] : 0;
      }
      
      // Buka box 'token_box' dengan encryption key
      _tokenBox = await Hive.openBox<String>(
        _boxName,
        encryptionCipher: HiveAesCipher(validKeyBytes),
      );
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize TokenJwtDAO: $e');
    }
  }

  /// Simpan JWT token ke Hive
  /// 
  /// [token]: JWT token string yang valid
  /// [expiresAt]: masa berlaku dari server (opsional; null = tidak diubah)
  /// Throws: Exception jika gagal simpan
  Future<void> saveToken(String token, {DateTime? expiresAt}) async {
    try {
      if (_tokenBox == null) {
        throw Exception('TokenJwtDAO not initialized. Call initialize() first.');
      }
      await _tokenBox!.put(_tokenKey, token);
      if (expiresAt != null) {
        await _tokenBox!.put(_expiryKey, expiresAt.toIso8601String());
      }
    } catch (e) {
      throw Exception('Failed to save token: $e');
    }
  }

  /// Masa berlaku token yang tersimpan.
  ///
  /// Returns: DateTime masa berlaku, atau null bila tidak tersimpan / tidak
  /// bisa dibaca (token lama sebelum kolom ini ada).
  DateTime? getExpiry() {
    try {
      final raw = _tokenBox?.get(_expiryKey);
      if (raw is! String || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    } catch (e) {
      debugPrint('Error getting token expiry: $e');
      return null;
    }
  }

  /// Ambil JWT token dari Hive
  /// 
  /// Returns: Token string jika ada, null jika tidak ada
  /// Hive otomatis decrypt sebelum return ke app
  String? getToken() {
    try {
      if (_tokenBox == null) return null;
      return _tokenBox!.get(_tokenKey);
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  /// Check apakah token ada di storage
  /// 
  /// Returns: true jika token ada, false jika tidak
  bool hasToken() {
    if (_tokenBox == null) return false;
    return _tokenBox!.containsKey(_tokenKey);
  }

  /// Hapus token dari Hive
  /// 
  /// Digunakan saat logout
  /// Throws: Exception jika gagal hapus
  Future<void> deleteToken() async {
    try {
      if (_tokenBox == null) return;
      await _tokenBox!.delete(_tokenKey);
      await _tokenBox!.delete(_expiryKey);
    } catch (e) {
      throw Exception('Failed to delete token: $e');
    }
  }

  /// Hapus semua data di token box
  /// 
  /// Nuclear option — clear seluruh box
  /// Useful untuk testing atau reset state
  Future<void> clear() async {
    try {
      if (_tokenBox == null) return;
      await _tokenBox!.clear();
    } catch (e) {
      throw Exception('Failed to clear token box: $e');
    }
  }

  /// Close Hive box — cleanup resources
  /// 
  /// Panggil saat app shutdown atau saat logout
  Future<void> close() async {
    try {
      if (_tokenBox == null) return;
      await _tokenBox!.close();
      _tokenBox = null;
      _isInitialized = false;
    } catch (e) {
      debugPrint('Error closing token box: $e');
    }
  }
}

