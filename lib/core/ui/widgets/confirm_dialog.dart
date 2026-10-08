// File: confirm_dialog.dart
// Dialog konfirmasi reusable untuk aksi yang tidak bisa dibatalkan.
//
// Prinsip: dialog ini HANYA dipakai untuk keputusan yang benar-benar mengubah
// keadaan petugas (logout, ganti gate, hapus antrean) — bukan konfirmasi untuk
// setiap aksi, karena itu justru melatih petugas menekan "YA" tanpa membaca.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Widget dialog konfirmasi standar aplikasi.
///
/// Bisa dipakai langsung di dalam `showDialog`, atau lewat helper
/// [showConfirmDialog] yang mengembalikan `Future<bool>`.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel,
    this.cancelLabel,
    this.destructive = true,
    this.icon,
    this.accentColor,
  });

  // Judul singkat — pertanyaan yang harus dijawab petugas.
  final String title;

  // Penjelasan konsekuensi aksi.
  final String message;

  // Teks tombol konfirmasi. Null → fallback ke terjemahan `common.confirm`.
  final String? confirmLabel;

  // Teks tombol batal. Null → fallback ke terjemahan `common.cancel`.
  final String? cancelLabel;

  // True → aksi merusak/mengakhiri sesi, tombol konfirmasi memakai warna bahaya.
  final bool destructive;

  // Ikon opsional di atas judul.
  final IconData? icon;

  // Warna aksen khusus; default mengikuti [destructive].
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);

    // Label tombol: pakai yang dikirim pemanggil, atau terjemahan default.
    final confirmText = confirmLabel ?? context.tr('common.confirm');
    final cancelText = cancelLabel ?? context.tr('common.cancel');

    // Warna aksi: eksplisit menang, lalu merah bila destruktif, selain itu primer.
    final accent =
        accentColor ?? (destructive ? c.used : c.primary);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xs,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ikon aksen (opsional) — membantu membedakan dialog serius dari biasa.
          if (icon != null) ...[
            Icon(icon, size: 22, color: accent),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(child: Text(title, style: text.sheetTitle)),
        ],
      ),
      content: Text(
        message,
        style: text.supporting.copyWith(fontSize: 14),
      ),
      actions: [
        // Tombol batal — selalu menutup dialog dengan hasil false.
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: c.inkMuted),
          child: Text(cancelText),
        ),
        // Tombol konfirmasi — hasil true, warna mengikuti tingkat bahaya aksi.
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: accent,
            textStyle: text.button,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}

/// Tampilkan dialog konfirmasi dan tunggu keputusan petugas.
///
/// Mengembalikan `true` bila petugas menekan tombol konfirmasi, dan `false`
/// bila menekan batal atau menutup dialog dengan cara lain (tap di luar /
/// tombol back) — sehingga pemanggil tidak perlu menangani null.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = true,
  IconData? icon = AppIcons.warning,
  Color? accentColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
      icon: icon,
      accentColor: accentColor,
    ),
  );

  // Dialog ditutup tanpa memilih → dianggap batal.
  return result ?? false;
}
