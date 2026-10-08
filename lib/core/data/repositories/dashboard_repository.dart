// File: dashboard_repository.dart
// Repository dashboard summary & ticket history.

import 'package:dio/dio.dart';

import '../../../features/dashboard/data/models/dashboard_stats.dart';
import '../../../features/history/data/models/scan_record_page.dart';
import '../../config/api_endpoints.dart';
import '../../error/api_failure.dart';
import '../../services/api_service.dart';

/// Kontrak akses endpoint dashboard dan riwayat scan.
///
/// Keduanya disatukan karena membaca agregat yang sama (scan petugas): angka
/// dashboard dan baris riwayat harus berasal dari sumber yang sama supaya tidak
/// saling bertentangan saat dibaca berdampingan.
abstract class DashboardRepository {
  /// Ringkasan metrik untuk [period].
  Future<DashboardStats> getSummary({StatsPeriod period = StatsPeriod.today});

  /// Satu halaman riwayat scan, terbaru lebih dulu.
  ///
  /// [checkpoint], [status] (`valid`, `already_used`, …), dan [date]
  /// (`YYYY-MM-DD`) adalah penyaring opsional; null berarti tanpa penyaring.
  Future<ScanRecordPage> getTicketHistory({
    int page = 1,
    int pageSize = 10,
    String? checkpoint,
    String? status,
    String? date,
  });
}

/// Implementasi berbasis [ApiService] (interceptor signing + encryption).
///
/// Selalu melempar [ApiFailure] supaya lapisan BLoC tidak perlu tahu Dio, dan
/// bisa membedakan "koneksi putus" dari "server menolak".
class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._apiService);

  final ApiService _apiService;

  // ==================== DASHBOARD SUMMARY ENDPOINT ====================

  @override
  Future<DashboardStats> getSummary({
    StatsPeriod period = StatsPeriod.today,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.dashboardSummary,
        queryParameters: {'period': period.wireValue},
      );

      final data = _payloadOf(response.data, 'dashboard');
      return DashboardStats.fromJson(data, period: period);
    } on ApiFailure {
      rethrow;
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    } catch (error) {
      throw ApiFailure.unexpected(error);
    }
  }

  // ==================== TICKET HISTORY ENDPOINT ====================

  @override
  Future<ScanRecordPage> getTicketHistory({
    int page = 1,
    int pageSize = 10,
    String? checkpoint,
    String? status,
    String? date,
  }) async {
    try {
      if (page < 1) {
        throw const ApiFailure(
          kind: ApiFailureKind.server,
          message: 'Page harus >= 1',
        );
      }
      if (pageSize < 1 || pageSize > 50) {
        throw const ApiFailure(
          kind: ApiFailureKind.server,
          message: 'Page size harus 1-50',
        );
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };
      if (checkpoint != null && checkpoint.isNotEmpty) {
        queryParams['checkpoint'] = checkpoint;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (date != null && date.isNotEmpty) {
        queryParams['date'] = date;
      }

      final response = await _apiService.get(
        ApiEndpoints.ticketHistory,
        queryParameters: queryParams,
      );

      final data = _payloadOf(response.data, 'riwayat');
      return ScanRecordPage.fromJson(data, page: page, pageSize: pageSize);
    } on ApiFailure {
      rethrow;
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    } catch (error) {
      throw ApiFailure.unexpected(error);
    }
  }

  // ==================== HELPER METHODS ====================

  /// Ambil `data` dari response standar `{success, data, message}`.
  ///
  /// Payload tetap dibaca walaupun `success` bernilai false: sebagian backend
  /// menandai periode yang kosong sebagai bukan-sukses tapi tetap mengirim
  /// datanya. Payload kosong (mis. riwayat belum ada) tetap dianggap sukses —
  /// daftar kosong bukan kegagalan.
  Map<String, dynamic> _payloadOf(Object? body, String what) {
    if (body is! Map) {
      throw const ApiFailure(
        kind: ApiFailureKind.server,
        message: 'Respons server tidak dikenali',
      );
    }

    final data = body['data'];
    if (data is Map) return Map<String, dynamic>.from(data);

    throw ApiFailure(
      kind: ApiFailureKind.server,
      message: body['message'] as String? ?? 'Gagal mengambil data $what',
    );
  }
}
