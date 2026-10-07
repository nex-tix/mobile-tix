// File: encryption_service.dart
// AES-CBC encryption/decryption service
import 'package:encrypt/encrypt.dart' as encryptLib;
import '../config/env_config.dart';

class EncryptionService {
  const EncryptionService._();

  static late final encryptLib.Key _key;
  static late final encryptLib.IV _iv;
  static late final encryptLib.Encrypter _encrypter;

  static void initialize() {
    try {
      _key = encryptLib.Key.fromUtf8(EnvConfig.secretKey);
      _iv = encryptLib.IV.fromUtf8(EnvConfig.iv);
      _encrypter = encryptLib.Encrypter(encryptLib.AES(_key, mode: encryptLib.AESMode.cbc));
    } catch (e) {
      throw Exception('Failed to initialize EncryptionService: $e');
    }
  }

  static String encrypt(String plainText) {
    try {
      if (plainText.isEmpty) return '';
      return _encrypter.encrypt(plainText, iv: _iv).base64;
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  static String decrypt(String cipherText) {
    try {
      if (cipherText.isEmpty) return '';
      final encrypted = encryptLib.Encrypted.fromBase64(cipherText);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  static String encryptToBase64(String plainText) => encrypt(plainText);
  static String decryptFromBase64(String base64Data) => decrypt(base64Data);
}
