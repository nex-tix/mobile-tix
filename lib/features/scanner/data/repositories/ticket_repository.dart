// File: ticket_repository.dart
// Repository dua endpoint validasi tiket (mode Cek & Check-in).

import 'package:dio/dio.dart';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/error/api_failure.dart';
import '../../../../core/services/api_service.dart';
import '../models/scan_result.dart';

/// Kontrak akses endpoint validasi tiket.
///
/// Dipisah dari `CheckpointRepository` (core) yang mengurus daftar gate: di sini
/// hanya ada dua operasi yang *menghasilkan verdict sebuah scan*, dan hanya di
/// sini pula scan offline di-replay.
abstract class TicketRepository {
  /// Mode Cek — membaca status tiket tanpa mengubahnya.
  Future<ScanResult> checkTicket({
    required String ticketCode,
    required String checkpointId,
  });

  /// Mode Check-in — validasi sekaligus menulis tiket.
  Future<ScanResult> validateAndCheckIn({
    required String ticketCode,
    required String checkpointId,
    int? actualVisitorCount,
  });
}

/// Implementasi berbasis [ApiService] (interceptor signing + encryption).
///
/// Selalu melempar [ApiFailure] — pemanggil tidak perlu tahu apa pun tentang
/// Dio, dan bisa membedakan kegagalan koneksi (aman diantrekan offline) dari
/// penolakan server.
class TicketRepositoryImpl implements TicketRepository {
  TicketRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<ScanResult> checkTicket({
    required String ticketCode,
    required String checkpointId,
  }) => _scan(
    endpoint: ApiEndpoints.ticketCheck,
    mode: ScanMode.check,
    ticketCode: ticketCode,
    checkpointId: checkpointId,
  );

  @override
  Future<ScanResult> validateAndCheckIn({
    required String ticketCode,
    required String checkpointId,
    int? actualVisitorCount,
  }) => _scan(
    endpoint: ApiEndpoints.ticketValidateAndCheckin,
    mode: ScanMode.checkIn,
    ticketCode: ticketCode,
    checkpointId: checkpointId,
    actualVisitorCount: actualVisitorCount,
  );

  Future<ScanResult> _scan({
    required String endpoint,
    required ScanMode mode,
    required String ticketCode,
    required String checkpointId,
    int? actualVisitorCount,
  }) async {
    final code = ticketCode.trim();
    final checkpoint = checkpointId.trim();

    if (code.isEmpty) {
      throw const ApiFailure(
        kind: ApiFailureKind.server,
        message: 'Kode tiket tidak boleh kosong',
      );
    }
    if (checkpoint.isEmpty) {
      throw const ApiFailure(
        kind: ApiFailureKind.server,
        message: 'Checkpoint aktif belum dipilih',
      );
    }

    try {
      final payload = <String, dynamic>{
        'ticketCode': code,
        'checkpointId': checkpoint,
        if (actualVisitorCount != null) ...{
          'actual_visitor_count': actualVisitorCount,
          'actualVisitorCount': actualVisitorCount,
          'visitor_count': actualVisitorCount,
          'visitorCount': actualVisitorCount,
        },
      };

      final response = await _apiService.post(
        endpoint,
        data: payload,
      );

      final body = response.data;
      if (body is! Map) {
        throw const ApiFailure(
          kind: ApiFailureKind.server,
          message: 'Respons server tidak dikenali',
        );
      }

      // Sebagian backend mengirim NOT_FOUND / EXPIRED sebagai `success: false`
      // tapi tetap menyertakan payload status di dalamnya. Selama payload ada,
      // verdict-nya tetap harus dibaca — itu justru inti dari keenam status.
      final data = body['data'];
      if (data is Map) {
        return ScanResult.fromJson(Map<String, dynamic>.from(data), mode: mode);
      }

      throw ApiFailure(
        kind: ApiFailureKind.server,
        message: body['message'] as String? ?? 'Validasi tiket gagal diproses',
      );
    } on ApiFailure {
      rethrow;
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    } catch (error) {
      throw ApiFailure.unexpected(error);
    }
  }
}
