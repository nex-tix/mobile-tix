// File: mock_api_adapter.dart
// Mock API adapter untuk testing tanpa backend real
// Simulasi response dari 8 endpoint sesuai PRDMOBILE.md

import 'dart:convert';
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

  /// Helper untuk generate valid dummy JWT dengan expiration di masa depan (default 12 jam)
  static String generateMockJwt({
    String username = 'admin.gate',
    Duration ttl = const Duration(hours: 12),
  }) {
    final now = DateTime.now();
    final exp = now.add(ttl).millisecondsSinceEpoch ~/ 1000;
    final iat = now.millisecondsSinceEpoch ~/ 1000;

    final header = base64Url
        .encode(utf8.encode(json.encode({'alg': 'HS256', 'typ': 'JWT'})))
        .replaceAll('=', '');
    final payload = base64Url
        .encode(utf8.encode(json.encode({
          'sub': username,
          'name': 'Admin Gate',
          'iat': iat,
          'exp': exp,
        })))
        .replaceAll('=', '');
    const signature = 'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
    return '$header.$payload.$signature';
  }

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
      final token = generateMockJwt(username: username);
      // Sukses login — return dummy token dan user data
      return ApiResponse.success(
        data: {
          'token': token,
          'user': {
            'id': 1,
            'username': username,
            'name': 'Admin Gate',
            'role': 'validator',
            'checkpoint': checkpoint,
          },
          'expires_at': DateTime.now().add(const Duration(hours: 12)).toIso8601String(),
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

  /// Verdict yang dikembalikan server untuk sebuah kode tiket.
  ///
  /// Prefix `VALID` / `USED` / `EXPIRED` / `CANCEL` dipakai untuk menguji kontrak
  /// API secara eksplisit. Kode demo `TKT-…` mengikuti aturan digit terakhir yang
  /// sama dengan prototype, supaya walkthrough di layar tetap konsisten.
  /// Prefix `ERR` mensimulasikan kegagalan server (bukan verdict tiket).
  static String ticketStatusFor(String ticketCode) {
    final code = ticketCode.trim().toUpperCase();
    if (code.startsWith('ERR')) return 'server_error';
    if (code.startsWith('VALID')) return 'valid';
    if (code.startsWith('USED')) return 'already_used';
    if (code.startsWith('EXPIRED')) return 'expired';
    if (code.startsWith('CANCEL')) return 'cancelled';
    if (code.startsWith('TKT-')) {
      if (code.endsWith('4')) return 'already_used';
      if (code.endsWith('3')) return 'expired';
      if (code.endsWith('0') || code.endsWith('9')) return 'not_found';
      if (code.endsWith('1')) return 'cancelled';
      return 'valid';
    }
    return 'not_found';
  }

  /// Payload satu tiket, dalam bentuk yang sama dengan backend real.
  ///
  /// Semua lima verdict dikirim sebagai payload yang bisa dibaca `ScanResult`
  /// (statusnya bagian dari data, bukan kegagalan transport).
  Map<String, dynamic> _ticketPayload({
    required String code,
    required String status,
    required String checkpoint,
    required bool checkedIn,
  }) {
    final now = DateTime.now();
    final gate = checkpoint.trim().isEmpty ? 'Gate A' : checkpoint.trim();
    final valid = status == 'valid';
    final used = status == 'already_used';
    final withHolder = valid || used;
    final written = checkedIn && valid;

    return {
      'ticket_code': code,
      'status': status,
      'visitor_name': withHolder ? 'Rangga Prasetyo' : null,
      'visitor_count': withHolder ? 1 : 0,
      'category': withHolder ? 'Individu' : null,
      'used_at': used
          ? now.subtract(const Duration(minutes: 27)).toIso8601String()
          : (written ? now.toIso8601String() : null),
      'used_by': (used || written) ? 'Admin Gate' : null,
      'used_at_checkpoint': (used || written) ? gate : null,
      'expiry_date': status == 'expired'
          ? now.subtract(const Duration(days: 1)).toIso8601String()
          : now.add(const Duration(days: 1)).toIso8601String(),
      'is_checked_in': written,
      'message': ticketMessageFor(status, checkedIn: checkedIn),
    };
  }

  /// Pesan operator untuk tiap verdict.
  static String ticketMessageFor(String status, {required bool checkedIn}) {
    return switch (status) {
      'valid' => checkedIn ? 'Check-in berhasil' : 'Tiket valid',
      'already_used' => 'Tiket sudah pernah digunakan',
      'expired' => 'Tiket sudah kadaluarsa',
      'cancelled' => 'Tiket dibatalkan',
      _ => 'Tiket tidak ditemukan',
    };
  }

  /// Mock endpoint: POST /ticket/check
  ///
  /// Mode Cek — membaca status tiket tanpa mengubahnya.
  /// [ticketCode]: kode ticket dari QR scan atau manual input
  /// [checkpoint]: gate tempat petugas bertugas (tidak mengubah tiket)
  ///
  /// Returns: ApiResponse dengan payload tiket + salah satu dari lima status
  Future<ApiResponse<Map<String, dynamic>>> checkTicket({
    required String ticketCode,
    String checkpoint = '',
  }) async {
    // Simulasi network delay
    await Future.delayed(_networkDelay);

    final status = ticketStatusFor(ticketCode);
    if (status == 'server_error') {
      return ApiResponse.error(message: 'Terjadi kesalahan di server');
    }

    return ApiResponse.success(
      data: _ticketPayload(
        code: ticketCode,
        status: status,
        checkpoint: checkpoint,
        checkedIn: false,
      ),
      message: ticketMessageFor(status, checkedIn: false),
    );
  }

  /// Mock endpoint: POST /ticket/validate-and-checkin
  ///
  /// Validate ticket + proses check-in sekaligus (atomic operation).
  /// [ticketCode]: kode ticket dari QR scan atau manual input
  /// [checkpoint]: gate tempat check-in dilakukan
  ///
  /// Returns: ApiResponse dengan payload tiket setelah check-in untuk status valid
  Future<ApiResponse<Map<String, dynamic>>> validateAndCheckIn({
    required String ticketCode,
    required String checkpoint,
  }) async {
    // Simulasi network delay
    await Future.delayed(_networkDelay);

    final status = ticketStatusFor(ticketCode);
    if (status == 'server_error') {
      return ApiResponse.error(message: 'Terjadi kesalahan di server');
    }

    return ApiResponse.success(
      data: _ticketPayload(
        code: ticketCode,
        status: status,
        checkpoint: checkpoint,
        checkedIn: true,
      ),
      message: ticketMessageFor(status, checkedIn: true),
    );
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
