// File: token_jwt_dao.dart
// Data Access Object untuk JWT token storage dengan encryption

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

  // Singleton instance — hanya 1 DAO untuk token
  static final TokenJwtDAO _instance = TokenJwtDAO._internal();
  
  // Factory constructor — return singleton instance
  factory TokenJwtDAO() => _instance;
  
  // Private internal constructor
  TokenJwtDAO._internal();

  // Reference ke Hive box
  // Late init karena box dibuka di initialize()
  late Box<String> _tokenBox;

  /// Initialize DAO — buka Hive box dengan encryption
  /// 
  /// Harus dipanggil 1x di main() sebelum app digunakan
  /// Throws: Exception jika gagal buka box
  Future<void> initialize() async {
    try {
      // Generate proper Hive encryption key dari EnvConfig.secretKey
      // EnvConfig.secretKey = 32-char string (256 bits untuk AES-256)
      // Convert string ke List<int> (bytes) untuk Hive AES cipher
      final keyBytes = EnvConfig.secretKey.codeUnits;
      
      // Pastikan key tepat 32 bytes (256 bits)
      // Hive butuh exact 32 bytes untuk AES-256 encryption
      if (keyBytes.length != 32) {
        throw Exception('Hive encryption key must be exactly 32 bytes');
      }
      
      // Buka box 'token_box' dengan encryption key
      // Box akan auto-encrypt semua value yang disimpan
      _tokenBox = await Hive.openBox<String>(
        _boxName,
        // Encryption cipher menggunakan AES-256
        // Setiap value di-encrypt sebelum disimpan ke disk
        encryptionCipher: HiveAesCipher(keyBytes),
      );
    } catch (e) {
      throw Exception('Failed to initialize TokenJwtDAO: $e');
    }
  }

  /// Simpan JWT token ke Hive
  /// 
  /// [token]: JWT token string yang valid
  /// Throws: Exception jika gagal simpan
  Future<void> saveToken(String token) async {
    try {
      // Put = insert or update di Hive
      // Key = _tokenKey, Value = token string
      // Hive otomatis encrypt sebelum simpan ke disk
      await _tokenBox.put(_tokenKey, token);
    } catch (e) {
      throw Exception('Failed to save token: $e');
    }
  }

  /// Ambil JWT token dari Hive
  /// 
  /// Returns: Token string jika ada, null jika tidak ada
  /// Hive otomatis decrypt sebelum return ke app
  String? getToken() {
    try {
      // Get = retrieve value berdasarkan key
      // Return null jika key tidak ada di box
      // Hive otomatis decrypt value sebelum return
      return _tokenBox.get(_tokenKey);
    } catch (e) {
      // Error handling — return null jika error
      print('Error getting token: $e');
      return null;
    }
  }

  /// Check apakah token ada di storage
  /// 
  /// Returns: true jika token ada, false jika tidak
  bool hasToken() {
    // ContainsKey = check apakah key ada di box
    // Lebih efficient daripada getToken() != null
    return _tokenBox.containsKey(_tokenKey);
  }

  /// Hapus token dari Hive
  /// 
  /// Digunakan saat logout
  /// Throws: Exception jika gagal hapus
  Future<void> deleteToken() async {
    try {
      // Delete = remove value berdasarkan key dari box
      await _tokenBox.delete(_tokenKey);
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
      // Clear = delete semua entries di box
      await _tokenBox.clear();
    } catch (e) {
      throw Exception('Failed to clear token box: $e');
    }
  }

  /// Close Hive box — cleanup resources
  /// 
  /// Panggil saat app shutdown atau saat logout
  Future<void> close() async {
    try {
      // Close = release resources, tutup akses ke box
      // Setelah close, box tidak bisa diakses sampai initialize() lagi
      await _tokenBox.close();
    } catch (e) {
      print('Error closing token box: $e');
    }
  }
}

