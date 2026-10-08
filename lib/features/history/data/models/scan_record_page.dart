// File: scan_record_page.dart
// Satu halaman riwayat scan + informasi paginasi.

import 'package:flutter/foundation.dart';

import 'scan_record.dart';

/// Satu halaman `GET /ticket/history`.
///
/// Membawa info paginasi dari server sekaligus keputusan "masih ada lagi?" yang
/// tidak boleh bergantung pada server mengirim `total_pages` — sebagian backend
/// hanya mengirim daftar itemnya.
@immutable
class ScanRecordPage {
  const ScanRecordPage({
    required this.items,
    required this.page,
    required this.pageSize,
    this.totalItems = 0,
    this.totalPages = 0,
  });

  final List<ScanRecord> items;

  /// Nomor halaman yang baru diambil (1-indexed).
  final int page;

  /// Jumlah item per halaman yang diminta.
  final int pageSize;

  /// Total item seluruh periode (bisa 0 bila server tidak mengirimnya).
  final int totalItems;

  /// Total halaman (bisa 0 bila server tidak mengirimnya).
  final int totalPages;

  bool get isEmpty => items.isEmpty;

  /// Masih ada halaman berikutnya.
  ///
  /// Bila server mengirim [totalPages], itu yang dipakai. Bila tidak, halaman
  /// penuh dianggap masih ada lanjutannya dan halaman pendek menandakan akhir —
  /// lebih baik satu request ekstra daripada daftar yang terpotong diam-diam.
  bool get hasMore => totalPages > 0 ? page < totalPages : items.length >= pageSize;

  /// Parse payload `{current_page, per_page, total_items, total_pages, items}`.
  factory ScanRecordPage.fromJson(
    Map<String, dynamic> json, {
    required int page,
    required int pageSize,
  }) {
    final rawItems = json['items'] ?? json['data'] ?? json['records'];
    final items = <ScanRecord>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          items.add(ScanRecord.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return ScanRecordPage(
      items: items,
      page: _int(json['current_page'] ?? json['currentPage']) ?? page,
      pageSize: _int(json['per_page'] ?? json['pageSize']) ?? pageSize,
      totalItems: _int(json['total_items'] ?? json['totalItems']) ?? 0,
      totalPages: _int(json['total_pages'] ?? json['totalPages']) ?? 0,
    );
  }

  @override
  String toString() =>
      'ScanRecordPage(page: $page, items: ${items.length}, '
      'total: $totalItems, hasMore: $hasMore)';
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString().trim() ?? '');
}
