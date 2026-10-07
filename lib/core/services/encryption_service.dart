// File: encryption_service.dart
// AES-CBC encryption/decryption service
import 'package:encrypt/encrypt.dart' as encryptLib;
import 'dart:typed_data';
import 'dart:math';
import '../config/env_config.dart';

class EncryptionService {
  const EncryptionService._();

  static late final encryptLib.Key _key;
  static late final encryptLib.Encrypter _encrypter;
  static final Random _random = Random.secure();

  static void initialize() {
    try {
      // Initialize key dari EnvConfig (32 chars = 256 bits)
      _key = encryptLib.Key.fromUtf8(EnvConfig.secretKey);
      
      // Encrypter untuk AES-CBC mode
      _encrypter = encryptLib.Encrypter(encryptLib.AES(_key, mode: encryptLib.AESMode.cbc));
    } catch (e) {
      throw Exception('Failed to initialize EncryptionService: $e');
    }
  }

  /// Encrypt plaintext dengan random IV per-request
  /// 
  /// Returns: Base64-encoded string dalam format: IV+CIPHERTEXT
  /// IV (16 bytes) + encrypted data, lalu di-encode Base64
  static String encrypt(String plainText) {
    try {
      if (plainText.isEmpty) return '';

      // Generate random IV (16 bytes) untuk request ini
      // Random IV: setiap encrypt call punya IV berbeda
      // Ini mencegah pattern analysis (same plaintext → different ciphertext)
      final ivBytes = Uint8List.fromList(
        List<int>.generate(16, (_) => _random.nextInt(256)),
      );
      final iv = encryptLib.IV(ivBytes);

      // Encrypt plaintext dengan IV yang baru di-generate
      final encrypted = _encrypter.encrypt(plainText, iv: iv);
      
      // Gabungkan IV + ciphertext, lalu Base64 encode
      // Format: [16 bytes IV][N bytes ciphertext]
      // IV tidak secret, boleh dikirim bareng ciphertext
      final combined = Uint8List.fromList([
        ...ivBytes,
        ...encrypted.bytes,
      ]);
      
      // Return Base64 encoded IV+ciphertext
      return encryptLib.Encrypted(combined).base64;
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypt ciphertext (Base64 encoded IV+CIPHERTEXT)
  /// 
  /// Returns: Decrypted plaintext
  /// Extract IV dari 16 bytes pertama, decrypt sisanya
  static String decrypt(String cipherText) {
    try {
      if (cipherText.isEmpty) return '';

      // Decode Base64 → bytes
      final combined = encryptLib.Encrypted.fromBase64(cipherText).bytes;
      
      // Extract IV dari 16 bytes pertama
      // IV selalu 16 bytes (128 bits) untuk AES
      final ivBytes = combined.sublist(0, 16);
      final iv = encryptLib.IV(Uint8List.fromList(ivBytes));
      
      // Extract ciphertext dari byte ke-17 sampai akhir
      final encryptedBytes = combined.sublist(16);
      final encrypted = encryptLib.Encrypted(Uint8List.fromList(encryptedBytes));
      
      // Decrypt dengan IV yang di-extract
      final decrypted = _encrypter.decrypt(encrypted, iv: iv);
      return decrypted;
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  static String encryptToBase64(String plainText) => encrypt(plainText);
  static String decryptFromBase64(String base64Data) => decrypt(base64Data);
}
