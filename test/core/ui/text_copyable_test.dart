// File: text_copyable_test.dart
// Widget test untuk TextCopyable (Commit 4.4).
//
// Yang diuji:
// - Nilai tampil apa adanya; mode hidden menampilkan masker.
// - Tap menyalin NILAI ASLI ke clipboard (bukan masker).
// - Snackbar umpan balik muncul setelah menyalin.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/theme/app_theme.dart';
import 'package:mobile_tix/core/ui/widgets/text_copyable.dart';

void main() {
  // Log panggilan platform channel — dipakai untuk memastikan isi clipboard.
  final platformCalls = <MethodCall>[];

  setUp(() {
    platformCalls.clear();

    // Mock channel Clipboard: catat panggilan, jangan sentuh OS.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  // Helper: render widget di dalam MaterialApp bertema aplikasi.
  Future<void> pumpWidgetUnderTest(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('menampilkan nilai asli saat hidden false', (tester) async {
    await pumpWidgetUnderTest(
      tester,
      const TextCopyable(value: 'TIX-2024-001', label: 'ID TIKET'),
    );

    expect(find.text('TIX-2024-001'), findsOneWidget);
    expect(find.text('ID TIKET'), findsOneWidget);
  });

  testWidgets('hidden true menampilkan masker, bukan nilai asli',
      (tester) async {
    await pumpWidgetUnderTest(
      tester,
      const TextCopyable(value: 'RAHASIA-123', hidden: true),
    );

    // Nilai asli tidak boleh terlihat di layar
    expect(find.text('RAHASIA-123'), findsNothing);
    // Masker yang tampil
    expect(find.text('••••••'), findsOneWidget);
  });

  testWidgets('tap menyalin nilai asli (bukan masker) ke clipboard',
      (tester) async {
    await pumpWidgetUnderTest(
      tester,
      const TextCopyable(value: 'RAHASIA-123', hidden: true, toast: false),
    );

    await tester.tap(find.byType(TextCopyable));
    await tester.pump();

    // Harus ada panggilan Clipboard.setData
    final setData = platformCalls.where(
      (c) => c.method == 'Clipboard.setData',
    );
    expect(setData, isNotEmpty);

    // Isi yang disalin = nilai asli, bukan '••••••'
    final args = setData.first.arguments as Map<Object?, Object?>;
    expect(args['text'], equals('RAHASIA-123'));
  });

  testWidgets('salin teks memunculkan snackbar umpan balik', (tester) async {
    await pumpWidgetUnderTest(
      tester,
      const TextCopyable(value: 'TIX-2024-001', copiedMessage: 'ID tiket disalin'),
    );

    await tester.tap(find.byType(TextCopyable));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('ID tiket disalin'), findsOneWidget);

    // Habiskan timer auto-dismiss snackbar
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
  });
}
