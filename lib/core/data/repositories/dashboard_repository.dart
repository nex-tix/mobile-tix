// File: dashboard_repository.dart
// Repository dashboard summary & ticket history.

import 'package:dio/dio.dart';

import '../../../features/dashboard/data/models/dashboard_stats.dart';
import '../../config/api_endpoints.dart';
import '../../error/api_failure.dart';
import '../../services/api_service.dart';

/// Model untuk 1 item di ticket history
///
/// Satu record check-in
class TicketHistoryItem {
  // Ticket ID
  final String ticketId;

  // Kode tiket
  final String ticketCode;

  // Nama pembeli
  final String buyerName;

  // Tipe tiket
  final String ticketType;

  // Checkpoint tempat check-in
  final String checkpointName;

  // Waktu check-in (ISO 8601)
  final String checkInTime;

  // Status (success, failed, cancelled)
  final String status;

  /// Constructor
  TicketHistoryItem({
    required this.ticketId,
    required this.ticketCode,
    required this.buyerName,
    required this.ticketType,
    required this.checkpointName,
    required this.checkInTime,
    required this.status,
  });

  /// Parse dari JSON
  factory TicketHistoryItem.fromJson(Map<String, dynamic> json) {
    return TicketHistoryItem(
      ticketId: json['ticketId'] as String? ?? '',
      ticketCode: json['ticketCode'] as String? ?? '',
      buyerName: json['buyerName'] as String? ?? '',
      ticketType: json['ticketType'] as String? ?? '',
      checkpointName: json['checkpointName'] as String? ?? '',
      checkInTime: json['checkInTime'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() => {
    'ticketId': ticketId,
    'ticketCode': ticketCode,
    'buyerName': buyerName,
    'ticketType': ticketType,
    'checkpointName': checkpointName,
    'checkInTime': checkInTime,
    'status': status,
  };
}

/// Paginated response untuk ticket history
///
/// Container untuk data + pagination info
class TicketHistoryResponse {
  // List item di halaman ini
  final List<TicketHistoryItem> items;

  // Total items seluruhnya
  final int totalItems;

  // Total halaman
  final int totalPages;

  // Halaman sekarang (1-indexed)
  final int currentPage;

  // Items per halaman
  final int pageSize;

  /// Constructor
  TicketHistoryResponse({
    required this.items,
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  /// Parse dari JSON
  factory TicketHistoryResponse.fromJson(Map<String, dynamic> json) {
    // Parse items list
    final itemsList = (json['items'] as List?)
        ?.map((item) => TicketHistoryItem.fromJson(item as Map<String, dynamic>))
        .toList() ?? [];

    return TicketHistoryResponse(
      items: itemsList,
      totalItems: json['totalItems'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      currentPage: json['currentPage'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'totalItems': totalItems,
    'totalPages': totalPages,
    'currentPage': currentPage,
    'pageSize': pageSize,
  };

  /// Check apakah ada halaman selanjutnya
  bool get hasNextPage => currentPage < totalPages;

  /// Check apakah halaman pertama
  bool get isFirstPage => currentPage == 1;

  /// Check apakah halaman terakhir
  bool get isLastPage => currentPage == totalPages;
}

/// Kontrak akses endpoint dashboard dan riwayat scan.
///
/// Keduanya disatukan karena membaca agregat yang sama (scan petugas): angka
/// dashboard dan baris riwayat harus berasal dari sumber yang sama supaya tidak
/// saling bertentangan saat dibaca berdampingan.
abstract class DashboardRepository {
  /// Ringkasan metrik untuk [period].
  Future<DashboardStats> getSummary({StatsPeriod period = StatsPeriod.today});

  /// Riwayat scan terhalaman.
  Future<TicketHistoryResponse> getTicketHistory({
    int page = 1,
    int pageSize = 10,
    String? startDate,
    String? endDate,
    String? status,
  });

  /// Halaman berikutnya dari [currentResponse] (untuk infinite scroll).
  Future<TicketHistoryResponse> getNextPage(
    TicketHistoryResponse currentResponse,
  );

  /// Halaman sebelumnya dari [currentResponse].
  Future<TicketHistoryResponse> getPreviousPage(
    TicketHistoryResponse currentResponse,
  );
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
  Future<TicketHistoryResponse> getTicketHistory({
    int page = 1,
    int pageSize = 10,
    String? startDate,
    String? endDate,
    String? status,
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
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _apiService.get(
        ApiEndpoints.ticketHistory,
        queryParameters: queryParams,
      );

      final data = _payloadOf(response.data, 'riwayat');
      return TicketHistoryResponse.fromJson(data);
    } on ApiFailure {
      rethrow;
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    } catch (error) {
      throw ApiFailure.unexpected(error);
    }
  }

  // ==================== HELPER METHODS ====================

  @override
  Future<TicketHistoryResponse> getNextPage(
    TicketHistoryResponse currentResponse,
  ) {
    if (!currentResponse.hasNextPage) {
      throw const ApiFailure(
        kind: ApiFailureKind.server,
        message: 'Sudah halaman terakhir',
      );
    }

    return getTicketHistory(
      page: currentResponse.currentPage + 1,
      pageSize: currentResponse.pageSize,
    );
  }

  @override
  Future<TicketHistoryResponse> getPreviousPage(
    TicketHistoryResponse currentResponse,
  ) {
    if (currentResponse.isFirstPage) {
      throw const ApiFailure(
        kind: ApiFailureKind.server,
        message: 'Sudah halaman pertama',
      );
    }

    return getTicketHistory(
      page: currentResponse.currentPage - 1,
      pageSize: currentResponse.pageSize,
    );
  }

  /// Ambil `data` dari response standar `{success, data, message}`.
  ///
  /// Payload tetap dibaca walaupun `success` bernilai false: sebagian backend
  /// menandai periode yang kosong sebagai bukan-sukses tapi tetap mengirim
  /// datanya. Yang benar-benar dianggap gagal hanyalah response tanpa payload.
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
