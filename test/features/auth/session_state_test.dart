// File: session_state_test.dart
// Regresi: petugas di sesi harus berasal dari akun yang login.
//
// Latar: dulu `setStaffAndCheckpoint` mengisi `dummyStaff` ("Admin Gate") saat
// pemanggil tidak mengirim data petugas, sehingga Profil selalu menampilkan
// nama bawaan, bukan nama akun yang dipakai login.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobile_tix/core/data/dao/checkpoint_dao.dart';
import 'package:mobile_tix/core/data/dao/staff_dao.dart';
import 'package:mobile_tix/features/auth/data/models/gate_staff.dart';
import 'package:mobile_tix/features/auth/logic/session_state.dart';
import 'package:mobile_tix/features/checkpoint/data/models/checkpoint.dart';

void main() {
  group('SessionState staff', () {
    const checkpoint = Checkpoint(
      id: 'cp-01',
      gate: 'Gerbang Utama',
      name: 'Pintu Utama',
      note: 'Shift pagi',
    );

    setUpAll(() {
      Hive.init(Directory.systemTemp.createTempSync('session_state_test').path);
    });

    setUp(() async {
      await StaffDAO().initialize();
      await CheckpointDAO().initialize();
      await Hive.box('staff_box').clear();
      await Hive.box('checkpoint_box').clear();
    });

    test('tanpa data petugas → staff tetap null (tidak ada nama bawaan)', () {
      final session = SessionState();

      expect(session.staff, isNull);
      expect(session.signedIn, isFalse);
    });

    test('setStaffAndCheckpoint menyimpan gate tanpa mengarang petugas', () async {
      final session = SessionState();
      await session.setStaffAndCheckpoint(checkpoint: checkpoint);

      expect(session.checkpoint?.id, equals('cp-01'));
      expect(session.staff, isNull);
    });

    test('petugas yang dikirim login tersimpan dan terbaca', () async {
      const staff = GateStaff(id: 4, name: 'rayamandara', username: 'raya');

      final session = SessionState();
      await session.setStaffAndCheckpoint(
        staff: staff,
        checkpoint: checkpoint,
      );

      expect(session.staff, equals(staff));
      expect(session.staff!.displayName, equals('rayamandara'));
      expect(session.signedIn, isTrue);
      expect(session.ready, isTrue);
    });

    test('aplikasi dibuka ulang → nama petugas tetap dari akun yang login', () async {
      const staff = GateStaff(id: 2, name: 'Validator 2', username: 'gate2');

      await SessionState()
          .setStaffAndCheckpoint(staff: staff, checkpoint: checkpoint);

      // Instance baru = app di-restart dengan token yang masih tersimpan.
      final restarted = SessionState();

      expect(restarted.staff, equals(staff));
      expect(restarted.staff!.initials, equals('V2'));
      expect(restarted.checkpoint?.gate, equals('Gerbang Utama'));
    });

    test('signOut membersihkan petugas dan gate aktif', () async {
      const staff = GateStaff(id: 1, name: 'Validator 1', username: 'gate1');

      final session = SessionState();
      await session.setStaffAndCheckpoint(
        staff: staff,
        checkpoint: checkpoint,
      );

      await session.signOut();

      expect(session.staff, isNull);
      expect(session.checkpoint, isNull);
      expect(StaffDAO().getStaff(), isNull);
      expect(CheckpointDAO().getActiveCheckpoint(), isNull);
    });
  });
}
