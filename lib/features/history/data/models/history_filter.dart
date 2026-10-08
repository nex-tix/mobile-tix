// File: history_filter.dart
// Filter daftar riwayat scan: status tiket, gate, dan tanggal.

import 'package:flutter/foundation.dart';

import '../../../../core/constants/ticket_status.dart';

/// Penyaring daftar riwayat.
///
/// Immutable dan punya kesetaraan nilai: cubit membandingkan filter baru dengan
/// yang sedang aktif untuk memutuskan perlu memuat ulang atau tidak. Field null
/// berarti "tanpa penyaring"; penyaring yang aktif selalu digabung dengan AND.
@immutable
class HistoryFilter {
  const HistoryFilter({
    this.status,
    this.checkpoint,
    this.date,
    this.rejectedOnly = false,
  });

  /// Tanpa penyaring sama sekali.
  static const HistoryFilter none = HistoryFilter();

  /// Hanya scan yang ditolak — semua verdict kecuali VALID.
  static const HistoryFilter rejected = HistoryFilter(rejectedOnly: true);

  /// Salah satu dari lima verdict; null = semua hasil (valid & ditolak).
  final TicketStatus? status;

  /// Nama gate; null = semua gate.
  final String? checkpoint;

  /// Tanggal scan (jam diabaikan); null = semua tanggal.
  final DateTime? date;

  /// True = kelompok "ditolak" alih-alih satu verdict pasti.
  ///
  /// Dipisah dari [status] karena keduanya berbeda arti: tab di layar gate
  /// menyaring sekelompok hasil (semua yang bukan VALID), sedang [status]
  /// menyaring tepat satu verdict. Digabung dalam satu field akan menghilangkan
  /// salah satu kemampuan.
  final bool rejectedOnly;

  bool get isUnfiltered =>
      status == null && checkpoint == null && date == null && !rejectedOnly;

  /// Nilai query param `status` yang dikirim ke API.
  ///
  /// `rejected` adalah nilai kelompok: semua verdict kecuali `valid`.
  String? get statusParam => rejectedOnly ? 'rejected' : status?.code;

  /// Nilai query param `date` (`YYYY-MM-DD`), null bila tanpa penyaring tanggal.
  String? get dateParam {
    final value = date;
    if (value == null) return null;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  /// Salinan dengan penyaring status pasti (dan melepas penyaring kelompok).
  HistoryFilter withStatus(TicketStatus? status) =>
      HistoryFilter(status: status, checkpoint: checkpoint, date: date);

  /// Salinan yang hanya menampilkan scan ditolak (melepas penyaring status pasti).
  HistoryFilter withRejectedOnly() =>
      HistoryFilter(checkpoint: checkpoint, date: date, rejectedOnly: true);

  /// Salinan dengan penyaring gate diganti (null = lepas penyaring).
  HistoryFilter withCheckpoint(String? checkpoint) => HistoryFilter(
    status: status,
    checkpoint: checkpoint,
    date: date,
    rejectedOnly: rejectedOnly,
  );

  /// Salinan dengan penyaring tanggal diganti (null = lepas penyaring).
  HistoryFilter withDate(DateTime? date) => HistoryFilter(
    status: status,
    checkpoint: checkpoint,
    date: date,
    rejectedOnly: rejectedOnly,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryFilter &&
          other.status == status &&
          other.checkpoint == checkpoint &&
          other.date == date &&
          other.rejectedOnly == rejectedOnly;

  @override
  int get hashCode => Object.hash(status, checkpoint, date, rejectedOnly);

  @override
  String toString() =>
      'HistoryFilter(status: ${statusParam ?? '-'}, '
      'gate: ${checkpoint ?? '-'}, tanggal: ${dateParam ?? '-'})';
}
