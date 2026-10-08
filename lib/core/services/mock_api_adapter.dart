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
  /// Ringkasan statistik dashboard.
  /// Query params: [period] — `today` (default) atau `month`.
  /// Query params: [date] — `YYYY-MM-DD`, hanya informatif pada mock.
  ///
  /// Angka sengaja saling konsisten: `hourly` berjumlah sama dengan
  /// `total_visitors`, begitu pula pecahan per gate dan per jenis pengunjung,
  /// serta `valid_tickets + rejected_tickets`. Dashboard yang angkanya
  /// bertentangan merusak kepercayaan pada seluruh layar.
  Future<ApiResponse<Map<String, dynamic>>> getDashboardSummary({
    String? period, // 'today' | 'month'
    String? date, // Format: YYYY-MM-DD, hanya dikembalikan apa adanya
  }) async {
    // Simulasi network delay
    await Future.delayed(_networkDelay);

    final resolved = period == 'month' ? 'month' : 'today';
    final now = DateTime.now();

    final metrics = resolved == 'month'
        ? <String, dynamic>{
            'period': 'month',
            'total_visitors': 3412,
            'valid_tickets': 3204,
            'rejected_tickets': 208,
            'by_checkpoint': {
              'Gate A': 1180,
              'Gate B': 1020,
              'Gate C': 860,
              'VIP Gate': 352,
            },
            'by_visitor_type': {
              'Regular': 2650,
              'VIP': 420,
              'Press': 190,
              'Staff': 152,
            },
            // Total pengunjung per jam operasional sepanjang bulan ini
            // (jumlah = 3412, sama dengan total_visitors).
            'hourly': [107, 240, 640, 480, 293, 160, 187, 320, 373, 240, 160, 133, 79],
            'hour_start': 8,
          }
        : <String, dynamic>{
            'period': 'today',
            'total_visitors': 128,
            'valid_tickets': 121,
            'rejected_tickets': 7,
            'by_checkpoint': {
              'Gate A': 45,
              'Gate B': 38,
              'Gate C': 32,
              'VIP Gate': 13,
            },
            'by_visitor_type': {
              'Regular': 98,
              'VIP': 18,
              'Press': 7,
              'Staff': 5,
            },
            'hourly': [4, 9, 24, 18, 11, 6, 7, 12, 14, 9, 6, 5, 3],
            'hour_start': 8,
          };

    return ApiResponse.success(
      data: {
        ...metrics,
        'date': date ?? now.toIso8601String().split('T')[0], // YYYY-MM-DD
        'last_updated': now.toIso8601String(),
      },
      message: 'Dashboard summary retrieved',
    );
  }

  /// Mock endpoint: GET /ticket/history
  ///
  /// Riwayat scan terhalaman, terbaru lebih dulu.
  /// Query params: [page] (1-indexed), [pageSize], [date] (YYYY-MM-DD),
  /// [checkpoint], [status].
  ///
  /// Semua filter benar-benar diterapkan dan hasilnya dipaginasi sungguhan,
  /// supaya perilaku "muat lebih banyak" serta penyaringan bisa diuji lewat HTTP
  /// mock — bukan hanya lewat unit test model.
  Future<ApiResponse<Map<String, dynamic>>> getTicketHistory({
    int page = 1, // Halaman ke berapa (1-indexed)
    int pageSize = 20, // Berapa item per halaman
    String? date, // Filter by date (YYYY-MM-DD)
    String? checkpoint, // Filter by checkpoint
    String? status, // Filter by status (valid, already_used, expired, …)
  }) async {
    // Simulasi network delay
    await Future.delayed(_networkDelay);

    final safePage = page < 1 ? 1 : page;
    final safeSize = pageSize < 1 ? 20 : pageSize;

    var records = historyRecords();

    if (status != null && status.isNotEmpty && status != 'all') {
      records = records.where((item) => item['status'] == status).toList();
    }
    if (checkpoint != null && checkpoint.isNotEmpty && checkpoint != 'all') {
      records = records
          .where((item) => item['checkpoint'] == checkpoint)
          .toList();
    }
    final day = date?.trim();
    if (day != null && day.isNotEmpty) {
      records = records
          .where(
            (item) => (item['scanned_at'] as String).startsWith(day),
          )
          .toList();
    }

    final totalItems = records.length;
    final totalPages = totalItems == 0
        ? 0
        : (totalItems + safeSize - 1) ~/ safeSize;
    final start = (safePage - 1) * safeSize;
    final end = (start + safeSize).clamp(0, totalItems);
    final items = start >= totalItems
        ? const <Map<String, dynamic>>[]
        : records.sublist(start, end);

    return ApiResponse.success(
      data: {
        'current_page': safePage,
        'per_page': safeSize,
        'total_items': totalItems,
        'total_pages': totalPages,
        'items': items,
      },
      message: 'Ticket history retrieved',
    );
  }

  /// Dataset riwayat yang deterministik untuk diuji.
  ///
  /// 27 baris dalam 3 hari terakhir (9 baris per hari). Status dan gate dirotasi
  /// supaya setiap kombinasi filter punya hasil, dan waktunya relatif terhadap
  /// [today] supaya filter tanggal selalu bisa diuji kapan pun demo dijalankan.
  static List<Map<String, dynamic>> historyRecords({DateTime? today}) {
    const statuses = [
      'valid',
      'already_used',
      'expired',
      'not_found',
      'cancelled',
    ];
    const gates = ['Gate A', 'Gate B', 'Gate C', 'VIP Gate'];

    final now = today ?? DateTime.now();
    final records = <Map<String, dynamic>>[];

    for (var i = 0; i < 27; i++) {
      final dayOffset = i ~/ 9;
      final status = statuses[i % statuses.length];
      final gate = gates[i % gates.length];
      final at = DateTime(
        now.year,
        now.month,
        now.day,
        9 + (i % 8),
        (i * 7) % 60,
      ).subtract(Duration(days: dayOffset));
      final withHolder = status == 'valid' || status == 'already_used';

      records.add({
        'id': 100 + i,
        'ticket_code': 'TKT-2026-${(1236 + i).toString().padLeft(6, '0')}',
        'status': status,
        'checkpoint': gate,
        'visitor_name': withHolder ? 'Tamu ${i + 1}' : null,
        'visitor_count': status == 'not_found' ? 0 : 1 + (i % 3),
        'category': withHolder ? (i.isEven ? 'Individu' : 'Rombongan') : null,
        'scanned_at': at.toIso8601String(),
        'validated_by': 'Admin Gate',
      });
    }

    // Terbaru lebih dulu, sesuai urutan yang diminta PRD.
    records.sort(
      (a, b) =>
          (b['scanned_at'] as String).compareTo(a['scanned_at'] as String),
    );
    return records;
  }
}
