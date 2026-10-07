import 'package:flutter/foundation.dart';

/// UI-only failure states. Nothing here is produced by a network call at this stage:
/// each one wraps a *simulated* condition so the prototype can show how the app
/// behaves when the real thing is wired in later.
@immutable
class UiFailure {
  const UiFailure({
    required this.kind,
    required this.title,
    required this.message,
    this.actionLabel,
  });

  final UiFailureKind kind;
  final String title;

  /// Names the problem and, where possible, the recovery.
  final String message;
  final String? actionLabel;

  static const UiFailure cameraPermission = UiFailure(
    kind: UiFailureKind.permission,
    title: 'Akses kamera diperlukan',
    message: 'Kamera digunakan untuk membaca QR tiket.',
    actionLabel: 'BUKA PENGATURAN',
  );

  static const UiFailure offline = UiFailure(
    kind: UiFailureKind.offline,
    title: 'Anda sedang offline',
    message: 'Pindai dinonaktifkan sampai koneksi kembali.',
  );

  static const UiFailure emptyHistory = UiFailure(
    kind: UiFailureKind.empty,
    title: 'Belum ada riwayat',
    message: 'Pindai tiket pertama Anda di gate ini untuk memulai log.',
  );

  static const UiFailure scannerBusy = UiFailure(
    kind: UiFailureKind.busy,
    title: 'Memproses',
    message: 'Membaca kode tiket…',
  );
}

enum UiFailureKind { permission, offline, empty, busy }
