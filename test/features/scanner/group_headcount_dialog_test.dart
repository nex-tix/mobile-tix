// File: group_headcount_dialog_test.dart
// Widget test dialog konfirmasi jumlah orang hadir tiket rombongan.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/constants/ticket_status.dart';
import 'package:mobile_tix/core/theme/app_colors.dart';
import 'package:mobile_tix/features/scanner/data/models/scan_result.dart';
import 'package:mobile_tix/features/scanner/presentation/widgets/group_headcount_dialog.dart';

void main() {
  Widget wrap({
    required ScanResult scanResult,
    required ValueChanged<int> onConfirm,
    required VoidCallback onCancel,
  }) {
    return MaterialApp(
      theme: ThemeData(
        extensions: const [AppColors.light],
      ),
      home: Scaffold(
        body: GroupHeadcountDialog(
          scanResult: scanResult,
          onConfirm: onConfirm,
          onCancel: onCancel,
        ),
      ),
    );
  }

  final groupResult = ScanResult(
    status: TicketStatus.valid,
    ticketCode: 'GRP-2026-008888',
    mode: ScanMode.checkIn,
    scannedAt: DateTime(2026, 10, 15, 10, 0),
    visitorName: 'Rombongan PT Maju Bersama',
    visitorCount: 10,
    category: 'Rombongan',
  );

  testWidgets('menampilkan kuota tiket awal dan nama rombongan', (tester) async {
    await tester.pumpWidget(
      wrap(
        scanResult: groupResult,
        onConfirm: (_) {},
        onCancel: () {},
      ),
    );

    expect(find.text('Konfirmasi Jumlah Hadir'), findsOneWidget);
    expect(find.text('10 Orang'), findsWidgets);
    expect(find.text('Rombongan PT Maju Bersama · GRP-2026-008888'), findsOneWidget);
    expect(find.textContaining('Konfirmasi Masuk (10 Orang)'), findsOneWidget);
  });

  testWidgets('stepper menambah jumlah hadir melebihi kuota menolak tiket dan menonaktifkan konfirmasi', (tester) async {
    int? confirmedAdmitted;

    await tester.pumpWidget(
      wrap(
        scanResult: groupResult,
        onConfirm: (count) => confirmedAdmitted = count,
        onCancel: () {},
      ),
    );

    // Tekan plus dua kali: 10 -> 11 -> 12
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('12'), findsOneWidget);
    expect(find.textContaining('melebihi kuota'), findsOneWidget);
    expect(find.textContaining('membeli tiket baru terpisah'), findsOneWidget);
    expect(find.text('Tiket Ditolak (Melebihi Kuota)'), findsOneWidget);

    // Tombol nonaktif (disabled) -> tap tidak memanggil onConfirm
    await tester.tap(
      find.text('Tiket Ditolak (Melebihi Kuota)'),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(confirmedAdmitted, isNull);

    // Jika diturunkan kembali ke kuota via tombol "Sesuai", tombol aktif kembali
    await tester.tap(find.text('Sesuai (10 Orang)'));
    await tester.pump();

    await tester.tap(find.textContaining('Konfirmasi Masuk (10 Orang)'));
    await tester.pump();

    expect(confirmedAdmitted, 10);
  });

  testWidgets('stepper mengurangi jumlah hadir dan menampilkan note jumlah riil', (tester) async {
    int? confirmedAdmitted;

    await tester.pumpWidget(
      wrap(
        scanResult: groupResult,
        onConfirm: (count) => confirmedAdmitted = count,
        onCancel: () {},
      ),
    );

    // Tekan minus dua kali: 10 -> 9 -> 8
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(find.text('8'), findsOneWidget);
    expect(find.textContaining('8 orang dicatat masuk'), findsOneWidget);
    expect(find.textContaining('2 orang tidak hadir'), findsOneWidget);

    // Saat kurang, tombol mengonfirmasi jumlah orang riil (8)
    await tester.tap(find.textContaining('Konfirmasi Masuk (8 Orang)'));
    await tester.pump();

    expect(confirmedAdmitted, 8);
  });

  testWidgets('tombol Sesuai mengembalikan jumlah hadir ke kuota semula', (tester) async {
    await tester.pumpWidget(
      wrap(
        scanResult: groupResult,
        onConfirm: (_) {},
        onCancel: () {},
      ),
    );

    // Tambah jadi 13
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('13'), findsOneWidget);

    // Tekan "Sesuai (10 Orang)"
    await tester.tap(find.text('Sesuai (10 Orang)'));
    await tester.pump();

    expect(find.text('10'), findsWidgets);
    expect(find.textContaining('sesuai dengan kuota tiket'), findsOneWidget);
  });

  testWidgets('tombol Batal memanggil callback onCancel', (tester) async {
    bool cancelled = false;

    await tester.pumpWidget(
      wrap(
        scanResult: groupResult,
        onConfirm: (_) {},
        onCancel: () => cancelled = true,
      ),
    );

    await tester.tap(find.text('Batal'));
    await tester.pump();

    expect(cancelled, isTrue);
  });
}
