// File: dashboard_stats_test.dart
// Unit test model DashboardStats (parsing payload dashboard).

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/features/dashboard/data/models/dashboard_stats.dart';

void main() {
  group('StatsPeriod', () {
    test('memetakan nilai wire yang dipakai query param', () {
      expect(StatsPeriod.today.wireValue, 'today');
      expect(StatsPeriod.month.wireValue, 'month');
      expect(StatsPeriod.fromWire('month'), StatsPeriod.month);
      expect(StatsPeriod.fromWire('today'), StatsPeriod.today);
    });

    test('nilai asing/null jatuh ke today, bukan crash', () {
      expect(StatsPeriod.fromWire(null), StatsPeriod.today);
      expect(StatsPeriod.fromWire('weekly'), StatsPeriod.today);
    });
  });

  group('DashboardStats.fromJson', () {
    test('membaca kontrak dashboard lengkap', () {
      final stats = DashboardStats.fromJson(
        {
          'period': 'today',
          'total_visitors': 128,
          'valid_tickets': 121,
          'rejected_tickets': 7,
          'by_checkpoint': {'Gate A': 45, 'Gate B': 83},
          'by_visitor_type': {'Regular': 98, 'VIP': 30},
          'hourly': [4, 9, 24],
          'hour_start': 8,
          'last_updated': '2026-10-08T05:30:00.000Z',
        },
        period: StatsPeriod.today,
      );

      expect(stats.period, StatsPeriod.today);
      expect(stats.totalVisitors, 128);
      expect(stats.validTickets, 121);
      expect(stats.rejectedTickets, 7);
      expect(stats.totalScanned, 128);
      expect(stats.byCheckpoint, {'Gate A': 45, 'Gate B': 83});
      expect(stats.byVisitorType, {'Regular': 98, 'VIP': 30});
      expect(stats.hourly, [4, 9, 24]);
      expect(stats.hourStart, 8);
      expect(stats.lastUpdated, isNotNull);
      expect(stats.isEmpty, isFalse);
      expect(stats.hasHourly, isTrue);
    });

    test('menerima camelCase dan field alternatif', () {
      final stats = DashboardStats.fromJson(
        {
          'totalVisitors': 10,
          'validTickets': 8,
          'rejectedTickets': 2,
          'byCheckpoint': {'Gate A': 10},
          'byVisitorType': {'VIP': 10},
          'hourlyData': [1, 2, 3],
          'hourStart': 6,
        },
        period: StatsPeriod.month,
      );

      expect(stats.totalVisitors, 10);
      expect(stats.validTickets, 8);
      expect(stats.rejectedTickets, 2);
      expect(stats.byCheckpoint, {'Gate A': 10});
      expect(stats.byVisitorType, {'VIP': 10});
      expect(stats.hourly, [1, 2, 3]);
      expect(stats.hourStart, 6);
    });

    test('payload kosong tetap menghasilkan objek yang bisa digambar', () {
      final stats = DashboardStats.fromJson(
        const <String, dynamic>{},
        period: StatsPeriod.today,
      );

      expect(stats.period, StatsPeriod.today);
      expect(stats.totalVisitors, 0);
      expect(stats.totalScanned, 0);
      expect(stats.isEmpty, isTrue);
      expect(stats.hasHourly, isFalse);
      expect(stats.byCheckpoint, isEmpty);
      expect(stats.hourStart, 8); // default jam buka
      expect(stats.lastUpdated, isNull);
    });

    test('periode yang diminta dipakai apa adanya', () {
      final stats = DashboardStats.fromJson(
        const {'period': 'today', 'total_visitors': 5},
        period: StatsPeriod.month,
      );

      expect(stats.period, StatsPeriod.month);
    });

    test('nilai non-numerik diabaikan, tidak membuat parsing meledak', () {
      final stats = DashboardStats.fromJson(
        {
          'total_visitors': 'banyak',
          'valid_tickets': 4.0,
          'by_checkpoint': {
            'Gate A': '12',
            'Gate B': null,
          },
          'hourly': [1, 'x', 3],
        },
        period: StatsPeriod.today,
      );

      expect(stats.totalVisitors, 0);
      expect(stats.validTickets, 4);
      expect(stats.byCheckpoint, {'Gate A': 12});
      expect(stats.hourly, [1, 3]);
    });
  });

  group('DashboardStats turunan', () {
    test('busiestCheckpoint memilih gate terbanyak', () {
      final stats = DashboardStats.fromJson(
        const {
          'by_checkpoint': {'Gate A': 45, 'Gate B': 83, 'Gate C': 32},
        },
        period: StatsPeriod.today,
      );

      expect(stats.busiestCheckpoint, 'Gate B');
    });

    test('busiestCheckpoint null saat pecahan per gate kosong', () {
      final stats = DashboardStats.fromJson(
        const <String, dynamic>{},
        period: StatsPeriod.today,
      );

      expect(stats.busiestCheckpoint, isNull);
    });

    test('peakIndex/peakCount/peakHour membaca jam tersibuk', () {
      final stats = DashboardStats.fromJson(
        const {
          'hourly': [4, 9, 24, 18],
          'hour_start': 8,
        },
        period: StatsPeriod.today,
      );

      expect(stats.peakIndex, 2);
      expect(stats.peakCount, 24);
      expect(stats.peakHour, 10);
    });

    test('peak tidak meledak saat seri per jam kosong', () {
      final stats = DashboardStats.fromJson(
        const <String, dynamic>{},
        period: StatsPeriod.today,
      );

      expect(stats.peakCount, 0);
      expect(stats.peakIndex, 0);
    });
  });
}
