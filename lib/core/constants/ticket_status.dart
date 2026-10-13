import 'package:flutter/material.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';

import '../theme/app_colors.dart';

/// The ticket vocabulary every screen speaks. One place owns the label, the
/// operator-facing instruction, and the colour role of each verdict, so the scanner,
/// the sheet, and the history log can never disagree about what "terpakai" means.
enum TicketStatus {
  valid(
    code: 'valid',
    label: 'VALID',
    shortLabel: 'Valid',
    instruction: 'Tiket sah. Persilakan masuk.',
  ),
  alreadyUsed(
    code: 'already_used',
    label: 'SUDAH DIPAKAI',
    shortLabel: 'Terpakai',
    instruction: 'Tiket sudah dipindai. Arahkan ke petugas.',
  ),
  expired(
    code: 'expired',
    label: 'KEDALUWARSA',
    shortLabel: 'Kedaluwarsa',
    instruction: 'Tiket di luar masa berlaku.',
  ),
  notYetValid(
    code: 'not_yet_valid',
    label: 'BELUM BERLAKU',
    shortLabel: 'Belum berlaku',
    instruction: 'Tiket belum masuk masa berlaku. Cek tanggal kunjungannya.',
  ),
  notFound(
    code: 'not_found',
    label: 'TIDAK DITEMUKAN',
    shortLabel: 'Tidak ditemukan',
    instruction:
        'Kode tidak dikenali. Periksa tiket atau masukkan kode manual.',
  ),
  cancelled(
    code: 'cancelled',
    label: 'DIBATALKAN',
    shortLabel: 'Dibatalkan',
    instruction: 'Tiket dibatalkan di sistem. Tolak masuk.',
  );

  const TicketStatus({
    required this.code,
    required this.label,
    required this.shortLabel,
    required this.instruction,
  });

  final String code;

  /// Stamped word — set in the condensed face, always uppercase.
  final String label;

  /// List/dense register.
  final String shortLabel;

  /// What the operator does next. Every failure state carries one.
  final String instruction;

  bool get isEntry => this == TicketStatus.valid;

  /// Petakan string status dari server ke salah satu dari enam verdict.
  ///
  /// Toleran terhadap variasi penulisan backend (`checked_in`, `used`, `void`…)
  /// dan mengembalikan [notFound] untuk apa pun yang tidak dikenali — termasuk
  /// null — supaya layar tidak pernah merender verdict kosong.
  static TicketStatus parse(Object? raw) {
    final value = raw?.toString().trim().toLowerCase();
    return switch (value) {
      'valid' || 'active' || 'checked_in' => TicketStatus.valid,
      'already_used' || 'used' || 'reused' => TicketStatus.alreadyUsed,
      'expired' => TicketStatus.expired,
      'not_yet_valid' || 'not_yet' || 'notyet' => TicketStatus.notYetValid,
      'cancelled' || 'canceled' || 'void' => TicketStatus.cancelled,
      _ => TicketStatus.notFound,
    };
  }

  Color ink(AppColors c) => switch (this) {
    TicketStatus.valid => c.valid,
    TicketStatus.alreadyUsed => c.used,
    TicketStatus.expired => c.expired,
    TicketStatus.notYetValid => c.notYet,
    TicketStatus.notFound => c.notFound,
    TicketStatus.cancelled => c.cancelled,
  };

  Color tint(AppColors c) => switch (this) {
    TicketStatus.valid => c.validTint,
    TicketStatus.alreadyUsed => c.usedTint,
    TicketStatus.expired => c.expiredTint,
    TicketStatus.notYetValid => c.notYetTint,
    TicketStatus.notFound => c.notFoundTint,
    TicketStatus.cancelled => c.cancelledTint,
  };

  /// True when the stamp may be set as ink on paper. Kedaluwarsa is the exception:
  /// mustard at that luminance can't hold 4.5:1 as text, so it is stamped as a
  /// filled block with ink on top instead.
  bool get stampIsInk => this != TicketStatus.expired;

  IconData get icon => switch (this) {
    TicketStatus.valid => AppIcons.check,
    TicketStatus.alreadyUsed => AppIcons.replay,
    TicketStatus.expired => AppIcons.schedule,
    TicketStatus.notYetValid => AppIcons.info,
    TicketStatus.notFound => AppIcons.searchOff,
    TicketStatus.cancelled => AppIcons.block,
  };
}
