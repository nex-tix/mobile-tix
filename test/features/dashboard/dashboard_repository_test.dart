// File: dashboard_repository_test.dart
// Unit test DashboardRepository — periode diteruskan ke API dan diparse benar.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/data/repositories/dashboard_repository.dart';
import 'package:mobile_tix/core/services/api_service.dart';
import 'package:mobile_tix/core/services/encryption_service.dart';
import 'package:mobile_tix/features/dashboard/data/models/dashboard_stats.dart';

void main() {
  group('DashboardRepository (mock API)', () {
    late DashboardRepository repository;

    setUpAll(() {
      EncryptionService.initialize();
    });

    setUp(() {
      // Mock diaktifkan eksplisit (EnvConfig.useMockApi bawaannya false).
      repository = DashboardRepositoryImpl(ApiService(useMockApi: true));
    });

    test('periode hari ini mengembalikan angka hari ini', () async {
      final stats = await repository.getSummary(period: StatsPeriod.today);

      expect(stats.period, StatsPeriod.today);
      expect(stats.totalVisitors, 128);
      expect(stats.validTickets, 121);
      expect(stats.rejectedTickets, 7);
    });

    test('periode bulan ini mengembalikan angka bulan ini', () async {
      final stats = await repository.getSummary(period: StatsPeriod.month);

      expect(stats.period, StatsPeriod.month);
      expect(stats.totalVisitors, 3412);
      expect(stats.validTickets, 3204);
      expect(stats.rejectedTickets, 208);
    });

    test('angka dashboard saling konsisten', () async {
      for (final period in StatsPeriod.values) {
        final stats = await repository.getSummary(period: period);

        // sah + ditolak = seluruh scan periode itu
        expect(
          stats.validTickets + stats.rejectedTickets,
          stats.totalScanned,
          reason: 'valid + ditolak harus sama dengan total scan ($period)',
        );
        // pecahan per gate dan per jenis pengunjung berjumlah sama dengan total
        expect(
          stats.byCheckpoint.values.fold<int>(0, (a, b) => a + b),
          stats.totalVisitors,
          reason: 'pecahan per gate harus berjumlah total pengunjung ($period)',
        );
        expect(
          stats.byVisitorType.values.fold<int>(0, (a, b) => a + b),
          stats.totalVisitors,
          reason:
              'pecahan per jenis pengunjung harus berjumlah total ($period)',
        );
        // seri per jam juga berjumlah total pengunjung
        expect(
          stats.hourly.fold<int>(0, (a, b) => a + b),
          stats.totalVisitors,
          reason: 'seri per jam harus berjumlah total pengunjung ($period)',
        );
      }
    });

    test('seri per jam dan jam buka ikut terkirim', () async {
      final stats = await repository.getSummary(period: StatsPeriod.today);

      expect(stats.hasHourly, isTrue);
      expect(stats.hourly.length, 13);
      expect(stats.hourStart, 8);
      expect(stats.peakHour, greaterThanOrEqualTo(stats.hourStart));
      expect(stats.busiestCheckpoint, isNotNull);
      expect(stats.lastUpdated, isNotNull);
    });

    test('tanpa argumen periode, default-nya hari ini', () async {
      final stats = await repository.getSummary();

      expect(stats.period, StatsPeriod.today);
      expect(stats.totalVisitors, 128);
    });
  });
}
