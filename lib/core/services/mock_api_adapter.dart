// File: mock_api_adapter.dart
// Mock API adapter untuk testing tanpa backend real
// Simulasi response dari 8 endpoint sesuai PRDMOBILE.md

import '../data/models/api_response_model.dart';

/// Mock API Adapter untuk simulasi backend responses
/// 
/// Gunakan ini saat backend belum ready atau untuk testing.
/// Setiap method return Future dengan delay 500ms untuk simulasi network latency.
/// Response format sama persis dengan backend real supaya gampang swap nanti.
class MockApiAdapter {
  // Singleton pattern — hanya 1 instance MockApiAdapter di seluruh app
  static final MockApiAdapter _instance = MockApiAdapter._internal();
  factory MockApiAdapter() => _instance;
  MockApiAdapter._internal();

  // Simulasi network delay (500ms)
  // Bisa diubah untuk test kondisi slow network
  static const Duration _networkDelay = Duration(milliseconds: 500);

  // ==================== AUTHENTICATION ====================

  /// Mock endpoint: POST /login
  /// 
  /// [username]: username dari login form (e.g., "admin.gate")
  /// [password]: password dari login form (e.g., "gate2026")
  /// [checkpoint]: gate/pintu yang dipilih (e.g., "Gate A")
  /// 
  /// Returns: ApiResponse dengan token JWT dan user info
  /// Success jika username == "admin.gate" dan password == "gate2026"
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String username,
    required String password,
    required String checkpoint,
  }) async {
    // Simulasi network delay
    await Future.delayed(_networkDelay);

    // Validasi credentials (hardcoded untuk mock)
    if (username == 'admin.gate' && password == 'gate2026') {
      // Sukses login — return dummy token dan user data
      return ApiResponse.success(
        data: {
          // JWT token dummy (12 jam TTL)
          // Token real akan di-generate oleh backend dengan format JWT standard
          'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbi5nYXRlIiwibmFtZSI6IkFkbWluIEdhdGUiLCJpYXQiOjE1MTYyMzkwMjIsImV4cCI6MTUxNjI4MjIyMn0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c',
          
          // User info
          'user': {
            'id': 1,
            'username': username,
            'name': 'Admin Gate',
            'role': 'validator', // Role: admin, validator, supervisor
            'checkpoint': checkpoint, // Gate yang dipilih saat login
          },
          
          // Token metadata
          'expires_at': DateTime.now().add(Duration(hours: 12)).toIso8601String(), // TTL 12 jam
        },
        message: 'Login berhasil',
      );
    } else {
      // Gagal login — invalid credentials
      return ApiResponse.error(
        message: 'Username atau password salah',
      );
    }
  }

  /// Mock endpoint: POST /logout
  /// 
  /// Tidak butuh parameter (token sudah ada di header Authorization)
  /// Returns: ApiResponse sukses/gagal
  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    // Simulasi network delay
    await Future.delayed(_networkDelay);

    // Logout selalu sukses
    return ApiResponse.success(
      data: {
        'logged_out_at': DateTime.now().toIso8601String(),
      },
      message: 'Logout berhasil',
    );
  }

  /// Mock endpoint: GET /me
  /// 
  /// Get current user info dari token
  /// Returns: ApiResponse dengan user data
  Future<ApiResponse<Map<String, dynamic>>> getCurrentUser() async {
    // Simulasi network delay
    await Future.delayed(_networkDelay);

    // Return dummy user data
    return ApiResponse.success(
      data: {
        'id': 1,
        'username': 'admin.gate',
        'name': 'Admin Gate',
        'role': 'validator',
        'checkpoint': 'Gate A', // Current checkpoint assignment
        'email': 'admin.gate@example.com',
        'phone': '+62812345678',
        'avatar_url': null, // Nullable — bisa null atau URL foto profile
      },
      message: 'User data retrieved',
    );
  }

  // ==================== CHECKPOINT MANAGEMENT ====================

  /// Mock endpoint: GET /checkpoints
  /// 
  /// Get list semua gate/checkpoint yang tersedia
  /// Returns: ApiResponse dengan array checkpoint
  Future<ApiResponse<List<Map<String, dynamic>>>> getCheckpoints() async {
    // Simulasi network delay
    await Future.delayed(_networkDelay);

    // Return list dummy checkpoints
    return ApiResponse.success(
      data: [
        {
          'id': 1,
          'name': 'Gate A',
          'code': 'GATE_A',
          'location': 'Pintu Masuk Utara',
          'is_active': true, // Apakah gate ini aktif atau tidak
        },
        {
          'id': 2,
          'name': 'Gate B',
          'code': 'GATE_B',
          'location': 'Pintu Masuk Selatan',
          'is_active': true,
        },
        {
          'id': 3,
          'name': 'Gate C',
          'code': 'GATE_C',
          'location': 'Pintu Masuk Timur',
          'is_active': true,
        },
        {
          'id': 4,
          'name': 'VIP Gate',
          'code': 'GATE_VIP',
          'location': 'Pintu VIP Barat',
          'is_active': true,
        },
      ],
      message: 'Checkpoint list retrieved',
    );
  }

  // ==================== TICKET VALIDATION ====================

  /// Mock endpoint: POST /ticket/check
  /// 
  /// Check apakah ticket valid atau tidak (tanpa proses check-in)
  /// [ticketCode]: kode ticket dari QR scan atau manual input
  /// 
  /// Returns: ApiResponse dengan ticket info dan status
  Future<ApiResponse<Map<String, dynamic>>> checkTicket({
    required String ticketCode,
  }) async {
    // Simulasi network delay
    await Future.delayed(_networkDelay);

    // Simulasi berbagai kondisi ticket berdasarkan kode
    if (ticketCode.startsWith('VALID')) {
      // Ticket valid — bisa di-check-in
      return ApiResponse.success(
        data: {
          'ticket_code': ticketCode,
          'status': 'valid', // Status: valid, invalid, already_used, expired
          'visitor_name': 'John Doe',
          'visitor_type': 'Regular', // Regular, VIP, Press, Staff
          'event_name': 'Kecak Dance Show',
          'event_date': '2026-10-07',
          'gate_allowed': ['Gate A', 'Gate B', 'Gate C'], // Gate mana saja yang boleh
          'check_in_time': null, // Null karena belum check-in
          'is_checked_in': false,
        },
        message: 'Ticket valid',
      );
    } else if (ticketCode.startsWith('USED')) {
      // Ticket sudah pernah digunakan
      return ApiResponse.error(
        message: 'Ticket sudah pernah digunakan',
      );
    } else if (ticketCode.startsWith('EXPIRED')) {
      // Ticket expired
      return ApiResponse.error(
        message: 'Ticket sudah kadaluarsa',
      );
    } else {
      // Ticket tidak ditemukan atau invalid format
      return ApiResponse.error(
        message: 'Ticket tidak valid atau tidak ditemukan',
      );
    }
  }

  /// Mock endpoint: POST /ticket/validate-and-checkin
  /// 
  /// Validate ticket + proses check-in sekaligus (atomic operation)
  /// [ticketCode]: kode ticket dari QR scan atau manual input
  /// [checkpoint]: gate tempat check-in dilakukan
  /// 
  /// Returns: ApiResponse dengan ticket info setelah check-in sukses
  Future<ApiResponse<Map<String, dynamic>>> validateAndCheckIn({
    required String ticketCode,
    required String checkpoint,
  }) async {
    // Simulasi network delay
    await Future.delayed(_networkDelay);

    // Simulasi berbagai kondisi ticket
    if (ticketCode.startsWith('VALID')) {
      // Check-in sukses
      return ApiResponse.success(
        data: {
          'ticket_code': ticketCode,
          'status': 'checked_in', // Status berubah jadi checked_in
          'visitor_name': 'John Doe',
          'visitor_type': 'Regular',
          'event_name': 'Kecak Dance Show',
          'event_date': '2026-10-07',
          'checkpoint': checkpoint, // Gate tempat check-in
          'check_in_time': DateTime.now().toIso8601String(), // Timestamp check-in
          'is_checked_in': true,
          'validator_name': 'Admin Gate', // Siapa yang melakukan check-in
        },
        message: 'Check-in berhasil',
      );
    } else if (ticketCode.startsWith('USED')) {
      // Ticket sudah pernah digunakan
      return ApiResponse.error(
        message: 'Ticket sudah pernah digunakan',
      );
    } else if (ticketCode.startsWith('EXPIRED')) {
      // Ticket expired
      return ApiResponse.error(
        message: 'Ticket sudah kadaluarsa',
      );
    } else {
      // Ticket tidak valid
      return ApiResponse.error(
        message: 'Ticket tidak valid atau tidak ditemukan',
      );
    }
  }

  // ==================== DASHBOARD & HISTORY ====================

  /// Mock endpoint: GET /dashboard/summary
  /// 
  /// Get ringkasan statistik untuk dashboard
  /// Query params: [date] (optional) — default hari ini
  /// 
  /// Returns: ApiResponse dengan summary metrics
  Future<ApiResponse<Map<String, dynamic>>> getDashboardSummary({
    String? date, // Format: YYYY-MM-DD, default hari ini
  }) async {
    // Simulasi network delay
    await Future.delayed(_networkDelay);

    // Return dummy dashboard metrics
    return ApiResponse.success(
      data: {
        'date': date ?? DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD
        'total_checked_in': 127, // Total check-in hari ini
        'total_valid': 145, // Total ticket valid yang dicek
        'total_invalid': 8, // Total ticket invalid
        'by_checkpoint': {
          // Breakdown per gate
          'Gate A': 45,
          'Gate B': 38,
          'Gate C': 32,
          'VIP Gate': 12,
        },
        'by_visitor_type': {
          // Breakdown per tipe visitor
          'Regular': 98,
          'VIP': 18,
          'Press': 7,
          'Staff': 4,
        },
        'last_updated': DateTime.now().toIso8601String(), // Kapan data di-update terakhir
      },
      message: 'Dashboard summary retrieved',
    );
  }

  /// Mock endpoint: GET /ticket/history
  /// 
  /// Get riwayat ticket validation/check-in
  /// Query params: [page], [limit], [date], [checkpoint], [status]
  /// 
  /// Returns: ApiResponse dengan paginated history
  Future<ApiResponse<Map<String, dynamic>>> getTicketHistory({
    int page = 1, // Pagination — halaman ke berapa
    int limit = 20, // Pagination — berapa item per halaman
    String? date, // Filter by date (YYYY-MM-DD)
    String? checkpoint, // Filter by checkpoint
    String? status, // Filter by status (valid, invalid, checked_in)
  }) async {
    // Simulasi network delay
    await Future.delayed(_networkDelay);

    // Return dummy history dengan pagination
    return ApiResponse.success(
      data: {
        'current_page': page,
        'per_page': limit,
        'total_items': 127, // Total seluruh items
        'total_pages': 7, // Total halaman (127 / 20 = 7 pages)
        'items': [
          // Array of ticket transaction
          {
            'id': 101,
            'ticket_code': 'VALID-20261007-001',
            'visitor_name': 'John Doe',
            'visitor_type': 'Regular',
            'checkpoint': 'Gate A',
            'status': 'checked_in',
            'check_in_time': '2026-10-07T05:30:00.000Z',
            'validator_name': 'Admin Gate',
          },
          {
            'id': 102,
            'ticket_code': 'VALID-20261007-002',
            'visitor_name': 'Jane Smith',
            'visitor_type': 'VIP',
            'checkpoint': 'VIP Gate',
            'status': 'checked_in',
            'check_in_time': '2026-10-07T05:32:15.000Z',
            'validator_name': 'Admin Gate',
          },
          {
            'id': 103,
            'ticket_code': 'INVALID-20261007-003',
            'visitor_name': null,
            'visitor_type': null,
            'checkpoint': 'Gate B',
            'status': 'invalid',
            'check_in_time': null, // Null karena gagal check-in
            'validator_name': 'Admin Gate',
          },
          // ... dst, total 20 items per page
        ],
      },
      message: 'Ticket history retrieved',
    );
  }
}
