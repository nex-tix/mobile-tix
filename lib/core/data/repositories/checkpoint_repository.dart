// File: checkpoint_repository.dart
// Repository untuk checkpoint dan ticket validation endpoints

import '../../services/api_service.dart';
import '../dao/checkpoint_dao.dart';
import '../dao/offline_queue_dao.dart';
import '../../config/api_endpoints.dart';

/// Model untuk checkpoint data
/// 
/// Representasi satu gate/pintu yang di-assign ke petugas
class CheckpointModel {
  // Unique ID checkpoint
  final String id;
  
  // Nama gate/pintu (contoh: "Pintu Masuk Utara", "Gate A1")
  final String name;
  
  // Lokasi gate (contoh: "Lantai 1", "Area Festival")
  final String? location;
  
  // Status aktif/non-aktif
  final String? status;
  
  // Event ID (jika ada multiple events)
  final String? eventId;

  /// Constructor
  CheckpointModel({
    required this.id,
    required this.name,
    this.location,
    this.status,
    this.eventId,
  });

  /// Parse dari JSON
  factory CheckpointModel.fromJson(Map<String, dynamic> json) {
    return CheckpointModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      location: json['location'] as String?,
      status: json['status'] as String?,
      eventId: json['eventId'] as String?,
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'status': status,
    'eventId': eventId,
  };
}

/// Model untuk ticket check response
/// 
/// Data ticket setelah scan/cek (belum check-in)
class TicketCheckResponse {
  // Ticket ID
  final String id;
  
  // Kode tiket (barcode/QR)
  final String ticketCode;
  
  // Nama event
  final String eventName;
  
  // Tipe tiket (VIP, Regular, dll)
  final String ticketType;
  
  // Nama pembeli
  final String buyerName;
  
  // Status tiket (valid, already_used, expired, invalid)
  final String status;
  
  // Waktu pembelian
  final String? purchaseDate;
  
  // Waktu check-in (jika sudah)
  final String? checkInTime;
  
  // Checkpoint ID (jika sudah check-in)
  final String? checkpointId;

  /// Constructor
  TicketCheckResponse({
    required this.id,
    required this.ticketCode,
    required this.eventName,
    required this.ticketType,
    required this.buyerName,
    required this.status,
    this.purchaseDate,
    this.checkInTime,
    this.checkpointId,
  });

  /// Parse dari JSON
  factory TicketCheckResponse.fromJson(Map<String, dynamic> json) {
    return TicketCheckResponse(
      id: json['id'] as String? ?? '',
      ticketCode: json['ticketCode'] as String? ?? '',
      eventName: json['eventName'] as String? ?? '',
      ticketType: json['ticketType'] as String? ?? '',
      buyerName: json['buyerName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      purchaseDate: json['purchaseDate'] as String?,
      checkInTime: json['checkInTime'] as String?,
      checkpointId: json['checkpointId'] as String?,
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'ticketCode': ticketCode,
    'eventName': eventName,
    'ticketType': ticketType,
    'buyerName': buyerName,
    'status': status,
    'purchaseDate': purchaseDate,
    'checkInTime': checkInTime,
    'checkpointId': checkpointId,
  };

  /// Check apakah tiket valid untuk check-in
  bool get isValidForCheckin => status == 'valid';
  
  /// Check apakah tiket sudah digunakan
  bool get isAlreadyUsed => status == 'already_used';
  
  /// Check apakah tiket expired
  bool get isExpired => status == 'expired';
}

/// Model untuk check-in response
/// 
/// Data setelah berhasil check-in
class CheckInResponse {
  // Ticket ID
  final String ticketId;
  
  // Status check-in (success/failed)
  final String status;
  
  // Waktu check-in (ISO 8601)
  final String checkInTime;
  
  // Checkpoint ID tempat check-in
  final String checkpointId;
  
  // Nama checkpoint
  final String checkpointName;
  
  // Pesan sukses/error
  final String? message;

  /// Constructor
  CheckInResponse({
    required this.ticketId,
    required this.status,
    required this.checkInTime,
    required this.checkpointId,
    required this.checkpointName,
    this.message,
  });

  /// Parse dari JSON
  factory CheckInResponse.fromJson(Map<String, dynamic> json) {
    return CheckInResponse(
      ticketId: json['ticketId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      checkInTime: json['checkInTime'] as String? ?? '',
      checkpointId: json['checkpointId'] as String? ?? '',
      checkpointName: json['checkpointName'] as String? ?? '',
      message: json['message'] as String?,
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() => {
    'ticketId': ticketId,
    'status': status,
    'checkInTime': checkInTime,
    'checkpointId': checkpointId,
    'checkpointName': checkpointName,
    'message': message,
  };

  /// Check apakah check-in berhasil
  bool get isSuccess => status == 'success';
}

/// Repository untuk checkpoint dan ticket operations
/// 
/// Handle:
/// - Get assigned checkpoints untuk petugas
/// - Check ticket (scan barcode/QR)
/// - Validate & check-in ticket
/// - Offline queue untuk check-in tanpa koneksi
class CheckpointRepository {
  // ApiService untuk API calls
  final ApiService _apiService;
  
  // CheckpointDAO untuk cache lokal (12h TTL)
  final CheckpointDAO _checkpointDAO;
  
  // OfflineQueueDAO untuk queue check-in offline
  final OfflineQueueDAO _offlineQueueDAO;

  /// Constructor dengan dependency injection
  CheckpointRepository(
    this._apiService,
    this._checkpointDAO,
    this._offlineQueueDAO,
  );

  // ==================== CHECKPOINTS ENDPOINT ====================

  /// Get checkpoints yang di-assign ke petugas
  /// 
  /// Returns: List of CheckpointModel
  /// Throws: Exception jika gagal
  /// 
  /// Flow:
  /// 1. Cek cache lokal (CheckpointDAO) — jika valid < 12h, return cache
  /// 2. Jika cache expired/kosong, call API /checkpoints
  /// 3. Simpan ke cache dengan timestamp
  /// 4. Return list checkpoints
  Future<List<CheckpointModel>> getCheckpoints({bool forceRefresh = false}) async {
    try {
      // Jika tidak force refresh, cek cache dulu
      if (!forceRefresh && _checkpointDAO.isCacheValid()) {
        // Get dari cache
        final cachedData = _checkpointDAO.getCheckpoints();
        if (cachedData != null && cachedData.isNotEmpty) {
          // Parse cache JSON ke model
          final checkpoints = (cachedData as List)
              .map((json) => CheckpointModel.fromJson(json as Map<String, dynamic>))
              .toList();
          return checkpoints;
        }
      }

      // Cache expired atau force refresh → call API
      // GET /checkpoints
      // Token auto-inject dari ApiService interceptor
      final response = await _apiService.get(
        ApiEndpoints.checkpoints,
      );

      // Parse response
      final responseData = response.data as Map<String, dynamic>;
      final success = responseData['success'] as bool? ?? false;
      
      if (!success) {
        throw Exception(responseData['message'] as String? ?? 'Gagal ambil checkpoints');
      }

      // Extract data
      final data = responseData['data'] as List?;
      if (data == null) {
        throw Exception('Data checkpoints tidak diterima');
      }

      // Parse ke model list
      final checkpoints = data
          .map((json) => CheckpointModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Simpan ke cache (overwrite cache lama)
      // Cast data ke List<Map<String, dynamic>> untuk DAO
      final dataForDao = (data as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      await _checkpointDAO.saveCheckpoints(dataForDao);

      return checkpoints;
    } catch (e) {
      print('Get checkpoints error: $e');
      rethrow;
    }
  }

  // ==================== TICKET CHECK ENDPOINT ====================

  /// Check ticket by barcode/QR code
  /// 
  /// [ticketCode]: Barcode atau QR code string
  /// Returns: TicketCheckResponse dengan detail tiket
  /// Throws: Exception jika gagal
  /// 
  /// Flow:
  /// 1. POST /ticket/check dengan body { "ticketCode": "..." }
  /// 2. Backend return data tiket + status
  /// 3. Return model untuk ditampilkan di UI
  Future<TicketCheckResponse> checkTicket(String ticketCode) async {
    try {
      // Validate input
      if (ticketCode.isEmpty) {
        throw Exception('Kode tiket tidak boleh kosong');
      }

      // Call /ticket/check endpoint
      final response = await _apiService.post(
        ApiEndpoints.ticketCheck,
        data: {'ticketCode': ticketCode},
      );

      // Parse response
      final responseData = response.data as Map<String, dynamic>;
      final success = responseData['success'] as bool? ?? false;
      
      if (!success) {
        throw Exception(responseData['message'] as String? ?? 'Tiket tidak ditemukan');
      }

      // Extract data
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Data tiket tidak diterima');
      }

      // Parse ke model
      return TicketCheckResponse.fromJson(data);
    } catch (e) {
      print('Check ticket error: $e');
      rethrow;
    }
  }

  // ==================== TICKET VALIDATE & CHECK-IN ENDPOINT ====================

  /// Validate dan check-in ticket
  /// 
  /// [ticketId]: ID tiket dari checkTicket response
  /// [checkpointId]: ID checkpoint tempat check-in
  /// Returns: CheckInResponse dengan hasil check-in
  /// Throws: Exception jika gagal
  /// 
  /// Flow:
  /// 1. Cek koneksi internet
  /// 2. Jika online: POST /ticket/validate-and-checkin
  /// 3. Jika offline: tambah ke OfflineQueueDAO
  /// 4. Return response atau queue status
  Future<CheckInResponse> validateAndCheckin({
    required String ticketId,
    required String checkpointId,
  }) async {
    try {
      // Validate input
      if (ticketId.isEmpty || checkpointId.isEmpty) {
        throw Exception('Ticket ID dan Checkpoint ID tidak boleh kosong');
      }

      // Build request body
      final body = {
        'ticketId': ticketId,
        'checkpointId': checkpointId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

      // Call /ticket/validate-and-checkin endpoint
      final response = await _apiService.post(
        ApiEndpoints.ticketValidateAndCheckin,
        data: body,
      );

      // Parse response
      final responseData = response.data as Map<String, dynamic>;
      final success = responseData['success'] as bool? ?? false;
      
      if (!success) {
        throw Exception(responseData['message'] as String? ?? 'Check-in gagal');
      }

      // Extract data
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Data check-in tidak diterima');
      }

      // Parse ke model
      return CheckInResponse.fromJson(data);
    } catch (e) {
      print('Validate and check-in error: $e');
      
      // Jika error network, tambah ke offline queue
      // TODO: Detect network error specifically
      // For now, rethrow saja (implementasi offline di commit selanjutnya)
      rethrow;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Clear checkpoint cache
  /// 
  /// Force refresh checkpoints dari server
  Future<void> clearCache() async {
    await _checkpointDAO.clear();
  }
}
