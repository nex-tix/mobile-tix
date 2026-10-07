// File: text_copyable.dart
// Widget teks dengan tombol salin (copy) + opsi masking.
//
// Dipakai untuk data yang sering dibutuhkan petugas di luar aplikasi:
// ID tiket, kode checkpoint, nomor batch. Menyalin dilakukan lewat satu tap
// dan selalu memberi umpan balik (snackbar atas) supaya tidak ada keraguan
// apakah teks benar-benar tersalin.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'app_snackbar.dart';

/// Teks yang bisa disalin dengan satu tap.
///
/// Pemakaian:
/// ```dart
/// TextCopyable(value: 'TIX-2024-001', label: 'ID TIKET')
/// TextCopyable(value: token, hidden: true)   // tampil ***** tapi menyalin aslinya
/// ```
class TextCopyable extends StatelessWidget {
  const TextCopyable({
    super.key,
    required this.value,
    this.label,
    this.hidden = false,
    this.style,
    this.iconSize = 18,
    this.copiedMessage = 'Teks disalin',
    this.toast = true,
  });

  // Nilai asli yang disalin ke clipboard (BUKAN nilai yang tampil).
  final String value;

  // Label kecil di atas teks (opsional), mis. "ID TIKET".
  final String? label;

  // True → nilai ditampilkan sebagai masker, tetapi clipboard tetap nilai asli.
  final bool hidden;

  // Style teks nilai; default memakai gaya `code` aplikasi.
  final TextStyle? style;

  // Ukuran ikon salin.
  final double iconSize;

  // Pesan snackbar setelah berhasil menyalin.
  final String copiedMessage;

  // False → salin tanpa memunculkan snackbar (mis. saat dipanggil di dalam dialog).
  final bool toast;

  /// Teks yang ditampilkan di layar: nilai asli, atau masker bila [hidden].
  String get displayValue => hidden ? '••••••' : value;

  /// Salin [value] ke clipboard lalu beri umpan balik.
  Future<void> _copy(BuildContext context) async {
    // Clipboard platform — nilai asli, bukan masker.
    await Clipboard.setData(ClipboardData(text: value));

    // Umpan balik: petugas harus tahu aksi berhasil tanpa menebak.
    if (toast && context.mounted) {
      AppSnackbar.success(context, copiedMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText.of(context);
    final valueStyle = style ?? text.code;

    return InkWell(
      // Seluruh baris bisa ditap, bukan hanya ikonnya.
      onTap: () => _copy(context),
      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bagian teks: label (opsional) di atas nilai.
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null) ...[
                    Text(label!, style: text.label),
                    const SizedBox(height: AppSpacing.xxs),
                  ],
                  Text(
                    displayValue,
                    style: valueStyle,
                    // Nilai panjang dipotong rapi, tidak merusak layout.
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Ikon salin — penanda visual bahwa baris ini bisa ditap.
            Icon(AppIcons.clipboard, size: iconSize, color: c.inkMuted),
          ],
        ),
      ),
    );
  }
}
