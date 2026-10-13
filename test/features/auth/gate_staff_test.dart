// File: gate_staff_test.dart
// Unit test model GateStaff — petugas diambil dari akun yang login.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/features/auth/data/models/gate_staff.dart';

void main() {
  group('GateStaff', () {
    test('membaca identitas dari balikan /login (bentuk gate_users)', () {
      final staff = GateStaff.fromJson({
        'id': 4,
        'name': 'rayamandara',
        'username': 'raya',
        'phone': '0887766554433',
      });

      expect(staff.id, 4);
      expect(staff.name, 'rayamandara');
      expect(staff.username, 'raya');
      expect(staff.phone, '0887766554433');
      expect(staff.displayName, 'rayamandara');
      expect(staff.initials, 'RA');
    });

    test('id dari JSON string tetap terbaca', () {
      final staff = GateStaff.fromJson({'id': '7', 'username': 'wiss'});
      expect(staff.id, 7);
    });

    test('field yang tidak dikirim server tidak membuat nilai karangan', () {
      final staff = GateStaff.fromJson({'username': 'gate1'});

      expect(staff.name, isEmpty);
      expect(staff.initials, isEmpty);
      expect(staff.phone, isNull);
      expect(staff.displayName, 'gate1');
    });

    test('inisial dua huruf dari nama', () {
      String initialsOf(String name) => GateStaff(
        name: name,
        username: 'x',
      ).initials;

      expect(initialsOf('Validator 1'), 'V1');
      expect(initialsOf('wisma'), 'WI');
      expect(initialsOf('aldy kurniawan'), 'AK');
      expect(initialsOf('   '), '');
      expect(initialsOf('A'), 'A');
    });

    test('toJson -> fromJson mengembalikan petugas yang sama', () {
      const staff = GateStaff(
        id: 1,
        name: 'Validator 1',
        username: 'gate1',
        phone: '08123',
      );

      expect(GateStaff.fromJson(staff.toJson()), equals(staff));
    });
  });
}
