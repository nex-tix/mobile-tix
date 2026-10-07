// File: dashboard_repository.dart
// Repository untuk dashboard dan ticket history endpoints

import '../../services/api_service.dart';
import '../../config/api_endpoints.dart';

/// Model untuk dashboard summary
/// 
/// Metrics dan statistik untuk home screen
class DashboardSummary {
  // Total tiket masuk hari ini
  final int totalTicketsToday;
  
  // Total tiket sudah check-in
  final int totalCheckedIn;
  
  // Persentase check-in rate
  final double checkInPercentage;
  
  // Total uang dari tiket (optional, untuk admin)
  final String? totalRevenue;
  
  // Event aktif hari ini
  final String? activeEvent;
  
  // List checkpoint aktif
  final List<CheckpointStatus> checkpoints;
  
  // Timestamp update data
  final String lastUpdated;

  /// Constructor
  DashboardSummary({
    required this.totalTicketsToday,
    required this.totalCheckedIn,
    required this.checkInPercentage,
    this.totalRevenue,
    this.activeEvent,
    required this.checkpoints,
    required this.lastUpdated,
  });

  /// Parse dari JSON
  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    // Parse checkpoints list
    final checkpointsList = (json['checkpoints'] as List?)
        ?.map((item) => CheckpointStatus.fromJson(item as Map<String, dynamic>))
        .toList() ?? [];

    return DashboardSummary(
      totalTicketsToday: json['totalTicketsToday'] as int? ?? 0,
      totalCheckedIn: json['totalCheckedIn'] as int? ?? 0,
      checkInPercentage: (json['checkInPercentage'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: json['totalRevenue'] as String?,
      activeEvent: json['activeEvent'] as String?,
      checkpoints: checkpointsList,
      lastUpdated: json['lastUpdated'] as String? ?? '',
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() => {
    'totalTicketsToday': totalTicketsToday,
    'totalCheckedIn': totalCheckedIn,
    'checkInPercentage': checkInPercentage,
    'totalRevenue': totalRevenue,
    'activeEvent': activeEvent,
    'checkpoints': checkpoints.map((cp) => cp.toJson()).toList(),
    'lastUpdated': lastUpdated,
  };
}

/// Model untuk status checkpoint di dashboard
/// 
/// Real-time info checkpoint
class CheckpointStatus {
  // ID checkpoint
  final String id;
  
  // Nama checkpoint/gate
  final String name;
  
  // Petugas yang di-assign
  final String? assignedPerson;
  
  // Status aktif/idle/closed
  final String status;
  
  // Jumlah tiket yang sudah di-scan di checkpoint ini
  final int ticketsScanned;

  /// Constructor
  CheckpointStatus({
    required this.id,
    required this.name,
    this.assignedPerson,
    required this.status,
    required this.ticketsScanned,
  });

  /// Parse dari JSON
  factory CheckpointStatus.fromJson(Map<String, dynamic> json) {
    return CheckpointStatus(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      assignedPerson: json['assignedPerson'] as String?,
      status: json['status'] as String? ?? '',
      ticketsScanned: json['ticketsScanned'] as int? ?? 0,
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'assignedPerson': assignedPerson,
    'status': status,
    'ticketsScanned': ticketsScanned,
  };
}

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

/// Repository untuk dashboard dan ticket history
/// 
/// Handle:
/// - Get dashboard summary (metrics hari ini)
/// - Get paginated ticket history
class DashboardRepository {
  // ApiService untuk API calls
  final ApiService _apiService;

  /// Constructor dengan dependency injection
  DashboardRepository(this._apiService);

  // ==================== DASHBOARD SUMMARY ENDPOINT ====================

  /// Get dashboard summary — metrics dan statistik
  /// 
  /// Returns: DashboardSummary dengan data hari ini
  /// Throws: Exception jika gagal
  /// 
  /// Flow:
  /// 1. GET /dashboard/summary
  /// 2. Token auto-inject dari interceptor
  /// 3. Backend return DashboardSummary JSON
  /// 4. Parse dan return model
  /// 
  /// Use case:
  /// - Home screen refresh setiap 30 detik
  /// - Show metrics: total tickets, check-in rate, checkpoint status
  Future<DashboardSummary> getDashboardSummary() async {
    try {
      // Call /dashboard/summary endpoint
      // GET request, token auto-inject
      final response = await _apiService.get(
        ApiEndpoints.dashboardSummary,
      );

      // Parse response
      // Backend format: { "success": true, "data": { ... }, "message": "..." }
      final responseData = response.data as Map<String, dynamic>;
      
      // Check success flag
      final success = responseData['success'] as bool? ?? false;
      if (!success) {
        throw Exception(
          responseData['message'] as String? ?? 'Gagal ambil dashboard summary'
        );
      }

      // Extract data field
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Data dashboard tidak diterima');
      }

      // Parse ke DashboardSummary model
      return DashboardSummary.fromJson(data);
    } catch (e) {
      print('Get dashboard summary error: $e');
      rethrow;
    }
  }

  // ==================== TICKET HISTORY ENDPOINT ====================

  /// Get paginated ticket history — list check-in records
  /// 
  /// [page]: Halaman (1-indexed, default 1)
  /// [pageSize]: Items per halaman (default 10, max 50)
  /// [startDate]: Filter mulai tanggal (ISO 8601, optional)
  /// [endDate]: Filter sampai tanggal (ISO 8601, optional)
  /// [status]: Filter by status (success/failed/cancelled, optional)
  /// 
  /// Returns: TicketHistoryResponse dengan paginated items
  /// Throws: Exception jika gagal
  /// 
  /// Flow:
  /// 1. GET /ticket/history?page=X&pageSize=Y&filters...
  /// 2. Token auto-inject dari interceptor
  /// 3. Backend return paginated history JSON
  /// 4. Parse dan return TicketHistoryResponse
  /// 
  /// Use case:
  /// - History screen dengan infinite scroll
  /// - Filter by date range, status
  /// - Load lebih banyak item saat scroll ke bawah
  Future<TicketHistoryResponse> getTicketHistory({
    int page = 1,
    int pageSize = 10,
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    try {
      // Validate input
      if (page < 1) {
        throw Exception('Page harus >= 1');
      }
      if (pageSize < 1 || pageSize > 50) {
        throw Exception('Page size harus 1-50');
      }

      // Build query parameters (convert to string for URL encoding)
      final queryParams = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      // Add optional filters
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      // Call /ticket/history endpoint dengan query params
      // GET request: /ticket/history?page=1&pageSize=10&...
      final response = await _apiService.get(
        ApiEndpoints.ticketHistory,
        queryParameters: queryParams,
      );

      // Parse response
      // Backend format: { "success": true, "data": { "items": [...], "totalItems": X, ... }, "message": "..." }
      final responseData = response.data as Map<String, dynamic>;
      
      // Check success flag
      final success = responseData['success'] as bool? ?? false;
      if (!success) {
        throw Exception(
          responseData['message'] as String? ?? 'Gagal ambil ticket history'
        );
      }

      // Extract data field
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Data history tidak diterima');
      }

      // Parse ke TicketHistoryResponse model
      return TicketHistoryResponse.fromJson(data);
    } catch (e) {
      print('Get ticket history error: $e');
      rethrow;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Get next page of ticket history
  /// 
  /// [currentResponse]: Response dari getTicketHistory sebelumnya
  /// Returns: TicketHistoryResponse halaman selanjutnya
  /// Throws: Exception jika tidak ada halaman selanjutnya
  /// 
  /// Convenience method untuk infinite scroll
  /// Contoh: if (response.hasNextPage) { nextResponse = getNextPage(response); }
  Future<TicketHistoryResponse> getNextPage(
    TicketHistoryResponse currentResponse,
  ) async {
    if (!currentResponse.hasNextPage) {
      throw Exception('Sudah halaman terakhir');
    }

    return getTicketHistory(
      page: currentResponse.currentPage + 1,
      pageSize: currentResponse.pageSize,
    );
  }

  /// Get previous page of ticket history
  /// 
  /// [currentResponse]: Response dari getTicketHistory
  /// Returns: TicketHistoryResponse halaman sebelumnya
  /// Throws: Exception jika halaman pertama
  Future<TicketHistoryResponse> getPreviousPage(
    TicketHistoryResponse currentResponse,
  ) async {
    if (currentResponse.isFirstPage) {
      throw Exception('Sudah halaman pertama');
    }

    return getTicketHistory(
      page: currentResponse.currentPage - 1,
      pageSize: currentResponse.pageSize,
    );
  }
}
