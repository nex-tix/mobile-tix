// File: confirm_dialog_test.dart
// Widget test untuk ConfirmDialog (Commit 4.4).
//
// Yang diuji:
// - Dialog menampilkan judul + pesan.
// - Tombol konfirmasi mengembalikan true.
// - Tombol batal mengembalikan false.
// - Menutup dialog dengan cara lain (tap barrier) tetap dianggap batal (false).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/theme/app_theme.dart';
import 'package:mobile_tix/core/ui/widgets/confirm_dialog.dart';

void main() {
  // Menyimpan hasil Future<bool> dari showConfirmDialog.
  bool? result;

  // Helper: app dengan tombol yang membuka dialog konfirmasi.
  Future<void> pumpHarness(
    WidgetTester tester, {
    bool destructive = true,
    String confirmLabel = 'LOGOUT',
  }) async {
    result = null;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showConfirmDialog(
                    context,
                    title: 'Keluar dari akun?',
                    message: 'Sesi saat ini akan diakhiri.',
                    confirmLabel: confirmLabel,
                    destructive: destructive,
                  );
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('menampilkan judul dan pesan', (tester) async {
    await pumpHarness(tester);

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    expect(find.text('Keluar dari akun?'), findsOneWidget);
    expect(find.text('Sesi saat ini akan diakhiri.'), findsOneWidget);
    expect(find.text('LOGOUT'), findsOneWidget);
    expect(find.text('BATAL'), findsOneWidget);

    // Selesaikan dialog supaya tidak ada sisa route
    await tester.tap(find.text('BATAL'));
    await tester.pumpAndSettle();
  });

  testWidgets('tombol konfirmasi mengembalikan true', (tester) async {
    await pumpHarness(tester);

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('LOGOUT'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('tombol batal mengembalikan false', (tester) async {
    await pumpHarness(tester);

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('BATAL'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('tap di luar dialog dianggap batal (false)', (tester) async {
    await pumpHarness(tester);

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    // Tap barrier (pojok atas layar) menutup dialog tanpa memilih
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('dialog non-destruktif tetap berfungsi', (tester) async {
    await pumpHarness(tester, destructive: false, confirmLabel: 'GANTI');

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('GANTI'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
