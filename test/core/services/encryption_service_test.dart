import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/services/encryption_service.dart';

void main() {
  group('EncryptionService Tests', () {
    setUpAll(() {
      EncryptionService.initialize();
    });

    test('Encrypt and decrypt returns original plaintext', () {
      const plaintext = 'Hello World 123! Indonesian & English';
      final encrypted = EncryptionService.encrypt(plaintext);

      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(plaintext)));

      final decrypted = EncryptionService.decrypt(encrypted);
      expect(decrypted, equals(plaintext));
    });

    test('Encrypting empty string returns empty string', () {
      expect(EncryptionService.encrypt(''), equals(''));
      expect(EncryptionService.decrypt(''), equals(''));
    });

    test('Different random IVs produce different ciphertexts for the same plaintext', () {
      const plaintext = 'Secret Data';
      final enc1 = EncryptionService.encrypt(plaintext);
      final enc2 = EncryptionService.encrypt(plaintext);

      expect(enc1, isNot(equals(enc2)));
      expect(EncryptionService.decrypt(enc1), equals(plaintext));
      expect(EncryptionService.decrypt(enc2), equals(plaintext));
    });
  });
}
