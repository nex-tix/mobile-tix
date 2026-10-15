// File: scan_record.dart
// Satu baris riwayat scan milik petugas.

import 'package:flutter/foundation.dart';

import '../../../../core/constants/ticket_status.dart';

/// Satu baris log gate: tiket apa yang dipindai, kapan, di mana, dan hasilnya.
///
/// Scan yang ditolak tetap dicatat — riwayat adalah catatan kejadian, bukan
/// daftar tamu yang masuk. Karena itu [status] bisa berisi keenam verdict.
@immutable
class ScanRecord {
  const ScanRecord({
    required this.ticketCode,
    required this.status,
    required this.scannedAt,
    this.checkpoint,
    this.visitorName,
    this.visitorCount = 1,
    this.category,
    this.validatedBy,
  });

  /// Kode tiket yang dipindai.
  final String ticketCode;

  /// Hasil scan — salah satu dari enam verdict.
  final TicketStatus status;

  /// Waktu scan terjadi (waktu perangkat, sudah dikonversi ke waktu lokal).
  final DateTime scannedAt;

  /// Gate tempat scan dilakukan.
  final String? checkpoint;

  /// Nama pembawa tiket (null untuk NOT_FOUND).
  final String? visitorName;

  /// Jumlah orang pada tiket ini.
  final int visitorCount;

  /// Jenis tiket — Individu, Rombongan, VIP…
  final String? category;

  /// Petugas yang memvalidasi.
  final String? validatedBy;

  /// Tiket ini membuka gate.
  bool get isValid => status == TicketStatus.valid;

  /// Tiket ini ditolak (empat verdict sisanya).
  bool get isRejected => !isValid;

  /// Identitas baris, dipakai menyaring duplikat saat halaman ditumpuk
  /// (halaman bisa tumpang tindih bila ada scan baru masuk di antara dua
  /// pengambilan).
  String get identity =>
      '$ticketCode|${scannedAt.toUtc().microsecondsSinceEpoch}';

  /// Tanggal scan tanpa jam, dalam waktu lokal — dasar filter per tanggal.
  DateTime get scanDate =>
      DateTime(scannedAt.year, scannedAt.month, scannedAt.day);

  /// Parse satu item payload `GET /ticket/history`.
  ///
  /// Toleran terhadap snake_case (kontrak terdokumentasi) maupun camelCase, dan
  /// terhadap beberapa nama field alternatif yang dipakai versi backend lain.
  factory ScanRecord.fromJson(Map<String, dynamic> json) {
    final time =
        json['scanned_at'] ??
        json['scannedAt'] ??
        json['check_in_time'] ??
        json['checkInTime'];

    return ScanRecord(
      ticketCode:
          _string(json['ticket_code'] ?? json['ticketCode']) ?? '',
      status: TicketStatus.parse(json['status']),
      scannedAt: _date(time) ?? DateTime.now(),
      checkpoint: _string(
        json['checkpoint'] ??
            json['checkpoint_name'] ??
            json['checkpointName'],
      ),
      visitorName: _string(
        json['visitor_name'] ??
            json['visitorName'] ??
            json['buyer_name'] ??
            json['buyerName'],
      ),
      visitorCount: _int(
            json['actual_visitor_count'] ??
                json['actualVisitorCount'] ??
                json['visitor_count'] ??
                json['visitorCount'],
          ) ??
          1,
      category: _string(
        json['category'] ??
            json['ticket_type'] ??
            json['ticketType'] ??
            json['visitor_type'] ??
            json['visitorType'],
      ),
      validatedBy: _string(
        json['validated_by'] ?? json['validator_name'] ?? json['validatorName'],
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanRecord &&
          other.ticketCode == ticketCode &&
          other.status == status &&
          other.scannedAt == scannedAt &&
          other.checkpoint == checkpoint &&
          other.visitorName == visitorName &&
          other.visitorCount == visitorCount &&
          other.category == category &&
          other.validatedBy == validatedBy;

  @override
  int get hashCode => Object.hash(
    ticketCode,
    status,
    scannedAt,
    checkpoint,
    visitorName,
    visitorCount,
    category,
    validatedBy,
  );

  @override
  String toString() =>
      'ScanRecord($ticketCode, ${status.code}, $scannedAt)';
}

String? _string(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_string(value) ?? '');
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final text = _string(value);
  if (text == null) return null;
  return DateTime.tryParse(text)?.toLocal();
}
