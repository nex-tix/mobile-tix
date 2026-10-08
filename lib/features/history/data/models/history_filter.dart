// File: history_filter.dart
// Filter daftar riwayat scan: status tiket, gate, dan tanggal.

import 'package:flutter/foundation.dart';

import '../../../../core/constants/ticket_status.dart';

/// Penyaring daftar riwayat.
///
/// Immutable dan punya kesetaraan nilai: cubit membandingkan filter baru dengan
/// yang sedang aktif untuk memutuskan perlu memuat ulang atau tidak. Field null
/// berarti "tanpa penyaring" — kombinasi ketiganya menyaring dengan AND.
@immutable
class HistoryFilter {
  const HistoryFilter({this.status, this.checkpoint, this.date});

  /// Tanpa penyaring sama sekali.
  static const HistoryFilter none = HistoryFilter();

  /// Salah satu dari lima verdict; null = semua hasil (valid & ditolak).
  final TicketStatus? status;

  /// Nama gate; null = semua gate.
  final String? checkpoint;

  /// Tanggal scan (jam diabaikan); null = semua tanggal.
  final DateTime? date;

  bool get isUnfiltered => status == null && checkpoint == null && date == null;

  /// Nilai yang dikirim sebagai query param `status`.
  String? get statusCode => status?.code;

  /// Nilai yang dikirim sebagai query param `date` (`YYYY-MM-DD`).
  String? get dateParam {
    final value = date;
    if (value == null) return null;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  /// Salinan dengan penyaring status diganti (null = lepas penyaring).
  HistoryFilter withStatus(TicketStatus? status) =>
      HistoryFilter(status: status, checkpoint: checkpoint, date: date);

  /// Salinan dengan penyaring gate diganti (null = lepas penyaring).
  HistoryFilter withCheckpoint(String? checkpoint) =>
      HistoryFilter(status: status, checkpoint: checkpoint, date: date);

  /// Salinan dengan penyaring tanggal diganti (null = lepas penyaring).
  HistoryFilter withDate(DateTime? date) =>
      HistoryFilter(status: status, checkpoint: checkpoint, date: date);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryFilter &&
          other.status == status &&
          other.checkpoint == checkpoint &&
          other.date == date;

  @override
  int get hashCode => Object.hash(status, checkpoint, date);

  @override
  String toString() =>
      'HistoryFilter(status: ${statusCode ?? '-'}, '
      'gate: ${checkpoint ?? '-'}, tanggal: ${dateParam ?? '-'})';
}
