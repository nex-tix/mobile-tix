// File: token_jwt_dao_test.dart
// Unit test untuk TokenJwtDAO (Commit 3.3 — persist & hapus JWT terenkripsi)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobile_tix/core/data/dao/token_jwt_dao.dart';

void main() {
  group('TokenJwtDAO Tests', () {
    late TokenJwtDAO dao;

    // Box Hive yang dipakai TokenJwtDAO (harus sama dengan konstanta di DAO)
    const boxName = 'token_box';
    const tokenKey = 'jwt_token';

    // JWT dummy — isi payload tidak dipakai DAO, hanya disimpan sebagai string
    const dummyJwt =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbi5nYXRlIn0.signature';

    setUpAll(() {
      // Init Hive di folder temp — aman untuk unit test tanpa Flutter binding
      Hive.init(Directory.systemTemp.createTempSync('token_jwt_dao_test').path);
    });

    setUp(() async {
      // Ambil singleton DAO lalu buka box (terenkripsi AES dengan secret key env)
      dao = TokenJwtDAO();
      await dao.initialize();

      // Bersihkan isi box supaya tiap test mulai dari kondisi kosong
      await Hive.box<String>(boxName).clear();
    });

    test('initialize → DAO siap dipakai', () {
      expect(dao.isInitialized, isTrue);
    });

    test('belum ada token → getToken null dan hasToken false', () {
      expect(dao.getToken(), isNull);
      expect(dao.hasToken(), isFalse);
    });

    test('saveToken lalu getToken mengembalikan token yang sama', () async {
      await dao.saveToken(dummyJwt);

      expect(dao.hasToken(), isTrue);
      expect(dao.getToken(), equals(dummyJwt));
    });

    test('masa berlaku token tersimpan dan terbaca', () async {
      final expiry = DateTime.now().add(const Duration(days: 7));

      await dao.saveToken(dummyJwt, expiresAt: expiry);

      expect(dao.getExpiry(), equals(expiry));
    });

    test('belum ada token → getExpiry null', () {
      expect(dao.getExpiry(), isNull);
    });

    test('deleteToken juga menghapus masa berlaku (logout)', () async {
      await dao.saveToken(
        dummyJwt,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      await dao.deleteToken();

      expect(dao.getToken(), isNull);
      expect(dao.getExpiry(), isNull);
    });

    test('saveToken menimpa token lama (hanya 1 record aktif)', () async {
      await dao.saveToken(dummyJwt);
      await dao.saveToken('token-baru');

      expect(dao.getToken(), equals('token-baru'));
    });

    test('deleteToken menghapus token (dipakai saat logout)', () async {
      await dao.saveToken(dummyJwt);
      expect(dao.hasToken(), isTrue);

      await dao.deleteToken();

      expect(dao.getToken(), isNull);
      expect(dao.hasToken(), isFalse);
    });

    test('clear menghapus seluruh isi box', () async {
      await dao.saveToken(dummyJwt);

      await dao.clear();

      // Box benar-benar kosong, bukan hanya key token yang hilang
      expect(Hive.box<String>(boxName).isEmpty, isTrue);
      expect(dao.getToken(), isNull);
    });

    test('token tersimpan terenkripsi di disk (bukan plaintext)', () async {
      await dao.saveToken(dummyJwt);

      // Nilai yang dibaca lewat box terenkripsi harus sama (decrypt otomatis)
      expect(Hive.box<String>(boxName).get(tokenKey), equals(dummyJwt));

      // File Hive tidak boleh memuat token apa adanya
      final hiveFile = File('${Hive.box<String>(boxName).path}/token_box.hive');
      if (hiveFile.existsSync()) {
        final raw = hiveFile.readAsBytesSync();
        final asLatin1 = String.fromCharCodes(raw);
        expect(asLatin1.contains(dummyJwt), isFalse);
      }
    });
  });
}
