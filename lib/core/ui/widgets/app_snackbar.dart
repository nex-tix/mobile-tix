// File: app_snackbar.dart
// API tingkat aplikasi untuk notifikasi atas (success / warning / danger / info).
//
// Lapisan ini memisahkan "apa yang mau diberitahukan" (AppSnackbar.success(...))
// dari "bagaimana notifikasi dianimasikan" (SnackbarTop). Pemanggil di feature
// tidak perlu tahu soal OverlayEntry.

import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'snackbar_top.dart';

/// Varian warna notifikasi — mengikuti makna status tiket di aplikasi.
enum AppSnackbarVariant {
  /// Aksi berhasil (tiket VALID, copy berhasil).
  success,

  /// Perlu perhatian, bukan kegagalan (tiket EXPIRED, offline queue).
  warning,

  /// Kegagalan (tiket ALREADY USED, error jaringan).
  danger,

  /// Informasi netral — tidak menandakan sukses/gagal.
  info,
}

/// Façade notifikasi atas.
///
/// Pemakaian:
/// ```dart
/// AppSnackbar.success(context, 'Tiket valid — dipersilakan masuk');
/// AppSnackbar.danger(context, 'Tiket sudah dipakai pada 14:02');
/// ```
class AppSnackbar {
  // Kelas utilitas statis — tidak untuk diinstansiasi.
  AppSnackbar._();

  /// Notifikasi sukses (ikon centang, aksen hijau).
  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      variant: AppSnackbarVariant.success,
      duration: duration,
    );
  }

  /// Notifikasi peringatan (ikon warning, aksen amber).
  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      variant: AppSnackbarVariant.warning,
      duration: duration,
    );
  }

  /// Notifikasi kegagalan (ikon danger, aksen merah) — tampil lebih lama
  /// karena biasanya butuh dibaca ulang oleh petugas.
  static void danger(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message: message,
      variant: AppSnackbarVariant.danger,
      duration: duration,
    );
  }

  /// Notifikasi informasi netral.
  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      variant: AppSnackbarVariant.info,
      duration: duration,
    );
  }

  /// Tutup notifikasi yang sedang tampil, jika ada.
  static void dismiss() => SnackbarTop.dismiss();

  // Builder bersama: satu tempat yang memetakan varian → ikon + warna + tombol tutup.
  static void _show(
    BuildContext context, {
    required String message,
    required AppSnackbarVariant variant,
    required Duration duration,
  }) {
    SnackbarTop.show(
      context,
      duration: duration,
      child: _AppSnackbarCard(
        message: message,
        variant: variant,
        onClose: SnackbarTop.dismiss,
      ),
    );
  }
}

/// Kartu notifikasi: ikon status + pesan + tombol tutup manual.
class _AppSnackbarCard extends StatelessWidget {
  const _AppSnackbarCard({
    required this.message,
    required this.variant,
    required this.onClose,
  });

  // Teks yang ditampilkan.
  final String message;

  // Varian warna/ikon.
  final AppSnackbarVariant variant;

  // Aksi tombol silang.
  final VoidCallback onClose;

  /// Ikon per varian.
  IconData get _icon => switch (variant) {
    AppSnackbarVariant.success => AppIcons.checkCircle,
    AppSnackbarVariant.warning => AppIcons.warning,
    AppSnackbarVariant.danger => AppIcons.error,
    AppSnackbarVariant.info => AppIcons.info,
  };

  /// Warna aksen per varian, diambil dari palette aplikasi (bukan hex bebas).
  Color _accent(AppColors c) => switch (variant) {
    AppSnackbarVariant.success => c.valid,
    AppSnackbarVariant.warning => c.expired,
    AppSnackbarVariant.danger => c.used,
    AppSnackbarVariant.info => c.inkMuted,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);
    final accent = _accent(c);

    // Material + gutter jelas supaya kartu tidak terlihat "menempel" ke tepi
    // pada layar dengan sudut melengkung.
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        // Lebar maksimal: di tablet kartu tidak melebar penuh satu layar.
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            // Notifikasi selalu gelap di atas konten terang, agar kontras
            // terjaga di kedua tema.
            color: c.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: c.outlineStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ikon status berwarna — penanda cepat sebelum teks dibaca.
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(_icon, size: 20, color: accent),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Pesan — boleh multi-baris, mengisi ruang tersisa.
              Expanded(
                child: Text(
                  message,
                  style: text.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),

              // Tombol tutup manual (petugas bisa membersihkan layar sendiri).
              const SizedBox(width: AppSpacing.xs),
              InkResponse(
                onTap: onClose,
                radius: AppSpacing.lg,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxs),
                  child: Icon(
                    AppIcons.close,
                    size: 18,
                    color: c.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
