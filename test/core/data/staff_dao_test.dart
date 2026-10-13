// File: staff_dao_test.dart
// Unit test StaffDAO — identitas petugas yang login.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobile_tix/core/data/dao/staff_dao.dart';

void main() {
  group('StaffDAO Tests', () {
    late StaffDAO dao;

    // Harus sama dengan konstanta di StaffDAO
    const boxName = 'staff_box';

    setUpAll(() {
      Hive.init(Directory.systemTemp.createTempSync('staff_dao_test').path);
    });

    setUp(() async {
      dao = StaffDAO();
      await dao.initialize();
      await Hive.box(boxName).clear();
    });

    test('belum ada yang login → getStaff null', () {
      expect(dao.getStaff(), isNull);
    });

    test('save lalu get mengembalikan data yang sama', () async {
      await dao.saveStaff({
        'id': 4,
        'name': 'rayamandara',
        'username': 'raya',
        'phone': '0887766554433',
      });

      final saved = dao.getStaff();
      expect(saved, isNotNull);
      expect(saved!['name'], equals('rayamandara'));
      expect(saved['username'], equals('raya'));
    });

    test('clearStaff menghapus data petugas', () async {
      await dao.saveStaff({'id': 1, 'name': 'Validator 1', 'username': 'gate1'});
      expect(dao.getStaff(), isNotNull);

      await dao.clearStaff();
      expect(dao.getStaff(), isNull);
    });
  });
}
