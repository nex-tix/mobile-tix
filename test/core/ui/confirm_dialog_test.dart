// File: confirm_dialog_test.dart
// Widget test untuk ConfirmDialog (Commit 4.4 + i18n Commit 5.3).
//
// Yang diuji:
// - Dialog menampilkan judul + pesan.
// - Tombol konfirmasi mengembalikan true.
// - Tombol batal mengembalikan false.
// - Menutup dialog dengan cara lain (tap barrier) tetap dianggap batal (false).
// - Label default (BATAL) berasal dari kamus i18n.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/theme/app_theme.dart';
import 'package:mobile_tix/core/ui/widgets/confirm_dialog.dart';

void main() {
  // Menyimpan hasil Future<bool> dari showConfirmDialog.
  bool? result;

  setUp(() {
    // rootBundle menyimpan cache string; dibersihkan tiap test supaya delegate
    // EasyLocalization benar-benar memuat ulang kamus dan Localizations siap
    // sebelum interaksi dilakukan.
    rootBundle.clear();
  });

  // Helper: app dengan tombol yang membuka dialog konfirmasi.
  Future<void> pumpHarness(
    WidgetTester tester, {
    bool destructive = true,
    String confirmLabel = 'LOGOUT',
  }) async {
    result = null;

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('id'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('id'),
        startLocale: const Locale('id'),
        saveLocale: false,
        child: Builder(
          builder: (easyContext) => MaterialApp(
            locale: easyContext.locale,
            supportedLocales: easyContext.supportedLocales,
            localizationsDelegates: easyContext.localizationDelegates,
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
        ),
      ),
    );

    // Beri kesempatan EasyLocalization memuat kamus sebelum berinteraksi.
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
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
