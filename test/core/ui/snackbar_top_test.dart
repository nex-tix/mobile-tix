// File: snackbar_top_test.dart
// Widget test untuk top floating snackbar (Commit 4.4).
//
// Yang diuji:
// - AppSnackbar menampilkan pesan di overlay atas.
// - Notifikasi baru menggantikan notifikasi lama (tidak menumpuk).
// - Auto-dismiss berjalan setelah durasi habis.
// - Tombol tutup manual bekerja.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';
import 'package:mobile_tix/core/theme/app_theme.dart';
import 'package:mobile_tix/core/ui/widgets/app_snackbar.dart';
import 'package:mobile_tix/core/ui/widgets/snackbar_top.dart';

void main() {
  // Helper: bangun app kecil dengan satu tombol pemicu snackbar.
  Future<void> pumpHarness(
    WidgetTester tester, {
    required void Function(BuildContext context) onPressed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => onPressed(context),
                child: const Text('TRIGGER'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Pastikan tidak ada snackbar tertinggal antar test (state-nya statis).
  tearDown(() {
    SnackbarTop.dismiss();
  });

  testWidgets('success menampilkan pesan di layar', (tester) async {
    await pumpHarness(
      tester,
      onPressed: (c) => AppSnackbar.success(c, 'Tiket valid'),
    );

    // Trigger + selesaikan animasi masuk
    await tester.tap(find.text('TRIGGER'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Tiket valid'), findsOneWidget);
    expect(SnackbarTop.isVisible, isTrue);

    // Majukan waktu sampai auto-dismiss selesai → tidak ada timer menggantung
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tiket valid'), findsNothing);
    expect(SnackbarTop.isVisible, isFalse);
  });

  testWidgets('tiap varian menampilkan pesannya masing-masing',
      (tester) async {
    await pumpHarness(
      tester,
      onPressed: (c) => AppSnackbar.danger(c, 'Tiket sudah dipakai'),
    );

    await tester.tap(find.text('TRIGGER'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Tiket sudah dipakai'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('notifikasi baru menggantikan yang lama (tidak menumpuk)',
      (tester) async {
    await pumpHarness(
      tester,
      onPressed: (c) {
        AppSnackbar.info(c, 'Pesan pertama');
        AppSnackbar.info(c, 'Pesan kedua');
      },
    );

    await tester.tap(find.text('TRIGGER'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Hanya pesan terakhir yang tersisa di layar
    expect(find.text('Pesan pertama'), findsNothing);
    expect(find.text('Pesan kedua'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('tombol tutup manual menyembunyikan notifikasi', (tester) async {
    await pumpHarness(
      tester,
      onPressed: (c) => AppSnackbar.warning(c, 'Antrean offline: 3 tiket'),
    );

    await tester.tap(find.text('TRIGGER'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Antrean offline: 3 tiket'), findsOneWidget);

    // Tap ikon silang di kartu notifikasi
    await tester.tap(find.byIcon(AppIcons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Antrean offline: 3 tiket'), findsNothing);
  });
}
