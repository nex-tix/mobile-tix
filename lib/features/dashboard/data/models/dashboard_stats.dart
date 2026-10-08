// File: dashboard_stats.dart
// Statistik dashboard untuk satu periode (hari ini / bulan ini).

import 'package:flutter/foundation.dart';

/// Periode yang bisa dipilih di dashboard.
///
/// [wireValue] dipakai sebagai query param `?period=` ke `GET /dashboard/summary`.
enum StatsPeriod {
  today('HARI INI', 'Today', 'today'),
  month('BULAN INI', 'This Month', 'month');

  const StatsPeriod(this.label, this.shortLabel, this.wireValue);

  /// Register huruf besar — dipakai di kepala kolom.
  final String label;

  /// Register kalimat — dipakai di kontrol pemilih periode.
  final String shortLabel;

  /// Nilai yang dikirim ke API.
  final String wireValue;

  /// Kebalikan dari [wireValue]; nilai asing dianggap [today].
  static StatsPeriod fromWire(String? value) {
    for (final period in StatsPeriod.values) {
      if (period.wireValue == value) return period;
    }
    return StatsPeriod.today;
  }
}

/// Angka satu periode untuk dashboard gate.
///
/// Tiga angka yang dilihat supervisor — berapa yang masuk, berapa yang sah,
/// berapa yang ditolak — plus pecahannya per gate dan per jenis pengunjung.
/// [totalVisitors] adalah pengunjung yang benar-benar check-in, jadi ia tidak
/// harus sama dengan [totalScanned] (scan gagal tidak menambah pengunjung).
@immutable
class DashboardStats {
  const DashboardStats({
    required this.period,
    required this.totalVisitors,
    required this.validTickets,
    required this.rejectedTickets,
    this.byCheckpoint = const {},
    this.byVisitorType = const {},
    this.hourly = const [],
    this.hourStart = 8,
    this.lastUpdated,
  });

  final StatsPeriod period;

  /// Total pengunjung masuk (scan mode check-in yang sah).
  final int totalVisitors;

  /// Total tiket valid yang dipindai pada periode ini.
  final int validTickets;

  /// Total tiket ditolak (semua alasan).
  final int rejectedTickets;

  /// Pecahan pengunjung per nama gate.
  final Map<String, int> byCheckpoint;

  /// Pecahan pengunjung per jenis (Regular, VIP, Press, Staff…).
  final Map<String, int> byVisitorType;

  /// Pengunjung masuk per jam operasional, mulai dari [hourStart].
  /// Kosong bila server tidak mengirim seri ini.
  final List<int> hourly;

  /// Jam pertama pada [hourly].
  final int hourStart;

  final DateTime? lastUpdated;

  /// Semua scan pada periode ini — sah maupun ditolak.
  int get totalScanned => validTickets + rejectedTickets;

  /// Belum ada apa pun untuk digambar.
  bool get isEmpty => totalVisitors == 0 && totalScanned == 0;

  /// Ada seri per jam yang bisa digambar.
  bool get hasHourly => hourly.isNotEmpty;

  /// Gate dengan pengunjung terbanyak, null bila pecahan per gate kosong.
  String? get busiestCheckpoint {
    String? busiest;
    var best = -1;
    for (final entry in byCheckpoint.entries) {
      if (entry.value > best) {
        best = entry.value;
        busiest = entry.key;
      }
    }
    return busiest;
  }

  int get peakIndex {
    var best = 0;
    for (var i = 1; i < hourly.length; i++) {
      if (hourly[i] > hourly[best]) best = i;
    }
    return best;
  }

  int get peakCount => hourly.isEmpty ? 0 : hourly[peakIndex];

  int get peakHour => hourStart + peakIndex;

  /// Parse payload `GET /dashboard/summary`.
  ///
  /// [period] dipakai apa adanya (periode yang diminta), bukan nilai dari
  /// payload: server boleh tidak menggem-balikannya, dan permintaanlah yang
  /// menentukan arti angka-angka ini.
  factory DashboardStats.fromJson(
    Map<String, dynamic> json, {
    required StatsPeriod period,
  }) {
    return DashboardStats(
      period: period,
      totalVisitors:
          _int(
            json['total_visitors'] ??
                json['totalVisitors'] ??
                json['total_checked_in'],
          ) ??
          0,
      validTickets:
          _int(
            json['valid_tickets'] ?? json['validTickets'] ?? json['total_valid'],
          ) ??
          0,
      rejectedTickets:
          _int(
            json['rejected_tickets'] ??
                json['rejectedTickets'] ??
                json['total_invalid'],
          ) ??
          0,
      byCheckpoint: _intMap(json['by_checkpoint'] ?? json['byCheckpoint']),
      byVisitorType: _intMap(
        json['by_visitor_type'] ?? json['byVisitorType'],
      ),
      hourly: _intList(
        json['hourly'] ?? json['hourly_data'] ?? json['hourlyData'],
      ),
      hourStart: _int(json['hour_start'] ?? json['hourStart']) ?? 8,
      lastUpdated: _date(json['last_updated'] ?? json['lastUpdated']),
    );
  }

  @override
  String toString() =>
      'DashboardStats(${period.wireValue}, masuk: $totalVisitors, '
      'valid: $validTickets, ditolak: $rejectedTickets)';
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString().trim() ?? '');
}

Map<String, int> _intMap(Object? value) {
  if (value is! Map) return const {};
  final result = <String, int>{};
  for (final entry in value.entries) {
    final count = _int(entry.value);
    if (count != null) result[entry.key.toString()] = count;
  }
  return result;
}

List<int> _intList(Object? value) {
  if (value is! List) return const [];
  final result = <int>[];
  for (final item in value) {
    final count = _int(item);
    if (count != null) result.add(count);
  }
  return result;
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}
