// File: encryption_service.dart
// AES-CBC encryption/decryption service
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import '../config/env_config.dart';

class EncryptionService {
  const EncryptionService._();

  static encrypt_lib.Key? _key;
  static encrypt_lib.Encrypter? _encrypter;
  static final Random _random = Random.secure();

  /// Initialize EncryptionService. Can be called at app startup or lazily.
  static void initialize() {
    try {
      final keyString = EnvConfig.secretKey;
      final keyBytes = utf8.encode(keyString);
      final validKeyBytes = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        validKeyBytes[i] = i < keyBytes.length ? keyBytes[i] : 0;
      }
      _key = encrypt_lib.Key(validKeyBytes);
      _encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(_key!, mode: encrypt_lib.AESMode.cbc),
      );
    } catch (e) {
      throw Exception('Failed to initialize EncryptionService: $e');
    }
  }

  static encrypt_lib.Encrypter get _activeEncrypter {
    if (_encrypter == null) {
      initialize();
    }
    return _encrypter!;
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
      final iv = encrypt_lib.IV(ivBytes);

      // Encrypt plaintext dengan IV yang baru di-generate
      final encrypted = _activeEncrypter.encrypt(plainText, iv: iv);
      
      // Gabungkan IV + ciphertext, lalu Base64 encode
      // Format: [16 bytes IV][N bytes ciphertext]
      // IV tidak secret, boleh dikirim bareng ciphertext
      final combined = Uint8List.fromList([
        ...ivBytes,
        ...encrypted.bytes,
      ]);
      
      // Return Base64 encoded IV+ciphertext
      return encrypt_lib.Encrypted(combined).base64;
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
      final combined = encrypt_lib.Encrypted.fromBase64(cipherText).bytes;
      if (combined.length <= 16) {
        throw Exception('Ciphertext too short (must be > 16 bytes for IV + ciphertext)');
      }
      
      // Extract IV dari 16 bytes pertama
      // IV selalu 16 bytes (128 bits) untuk AES
      final ivBytes = combined.sublist(0, 16);
      final iv = encrypt_lib.IV(Uint8List.fromList(ivBytes));
      
      // Extract ciphertext dari byte ke-17 sampai akhir
      final encryptedBytes = combined.sublist(16);
      final encrypted = encrypt_lib.Encrypted(Uint8List.fromList(encryptedBytes));
      
      // Decrypt dengan IV yang di-extract
      final decrypted = _activeEncrypter.decrypt(encrypted, iv: iv);
      return decrypted;
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  static String encryptToBase64(String plainText) => encrypt(plainText);
  static String decryptFromBase64(String base64Data) => decrypt(base64Data);
}
