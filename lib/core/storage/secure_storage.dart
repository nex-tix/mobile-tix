import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const FlutterSecureStorage storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> write(String key, String value) async {
    await storage.write(key: key, value: value);
  }

  static Future<String?> read(String key) async {
    return await storage.read(key: key);
  }

  static Future<void> delete(String key) async {
    await storage.delete(key: key);
  }

  static Future<void> deleteAll() async {
    await storage.deleteAll();
  }
}
