// File: api_failure.dart
// Kegagalan lapisan API/network yang bisa dibedakan oleh pemanggil.

import 'package:dio/dio.dart';

/// Alasan sebuah permintaan API gagal.
///
/// Jenis ini dipakai lapisan fitur (mis. `ScannerCubit`) untuk memutuskan apakah
/// sebuah scan boleh dimasukkan ke antrean offline. Hanya [network] — koneksi
/// tidak pernah terbentuk — yang aman diulang nanti. Timeout **tidak** termasuk:
/// request bisa saja sudah sampai dan diproses server, sehingga mengirim ulang
/// berisiko melakukan check-in ganda.
enum ApiFailureKind {
  /// Tidak ada koneksi / koneksi ditolak sebelum request terkirim.
  network,

  /// Koneksi terbentuk tapi server tidak menjawab tepat waktu.
  timeout,

  /// Token ditolak (401) walaupun sudah dicoba refresh.
  unauthorized,

  /// Server menjawab, tapi dengan error (4xx/5xx) atau payload tidak sesuai.
  server,

  /// Penyebab lain yang tidak terklasifikasi.
  unknown,
}

/// Error domain untuk kegagalan API.
///
/// Seluruh repository melempar tipe ini (bukan `DioException`) supaya lapisan
/// BLoC tidak perlu tahu apa pun tentang Dio.
class ApiFailure implements Exception {
  const ApiFailure({
    required this.kind,
    required this.message,
    this.statusCode,
  });

  final ApiFailureKind kind;

  /// Pesan siap tampil — diambil dari server bila ada, jika tidak dari [kind].
  final String message;

  /// HTTP status code, null bila tidak ada respons sama sekali.
  final int? statusCode;

  /// True bila operasi boleh diantrekan offline dan dikirim ulang saat online.
  bool get isQueueable => kind == ApiFailureKind.network;

  /// Terjemahkan kegagalan Dio menjadi error domain.
  factory ApiFailure.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;

    final kind = switch (error.type) {
      DioExceptionType.connectionError => ApiFailureKind.network,
      DioExceptionType.connectionTimeout => ApiFailureKind.network,
      DioExceptionType.badCertificate => ApiFailureKind.network,
      DioExceptionType.sendTimeout => ApiFailureKind.timeout,
      DioExceptionType.receiveTimeout => ApiFailureKind.timeout,
      DioExceptionType.badResponse =>
        statusCode == 401 ? ApiFailureKind.unauthorized : ApiFailureKind.server,
      DioExceptionType.cancel => ApiFailureKind.unknown,
      DioExceptionType.unknown => ApiFailureKind.unknown,
      DioExceptionType.transformTimeout => ApiFailureKind.timeout,
    };

    return ApiFailure(
      kind: kind,
      message: _messageFor(kind, error, statusCode),
      statusCode: statusCode,
    );
  }

  /// Kegagalan tak terduga dari kode non-API (mis. parsing).
  factory ApiFailure.unexpected(Object error) => ApiFailure(
    kind: ApiFailureKind.unknown,
    message: 'Terjadi kesalahan yang tidak dikenali: $error',
  );

  static String _messageFor(
    ApiFailureKind kind,
    DioException error,
    int? statusCode,
  ) {
    // Pesan dari server selalu lebih informatif daripada teks generik kita.
    final body = error.response?.data;
    if (body is Map) {
      final serverMessage = body['message'];
      if (serverMessage is String && serverMessage.trim().isNotEmpty) {
        return serverMessage.trim();
      }
    }

    return switch (kind) {
      ApiFailureKind.network => 'Tidak ada koneksi ke server',
      ApiFailureKind.timeout => 'Server tidak merespons, coba lagi',
      ApiFailureKind.unauthorized => 'Sesi berakhir, silakan masuk ulang',
      ApiFailureKind.server =>
        statusCode == null
            ? 'Permintaan gagal diproses server'
            : 'Server menolak permintaan ($statusCode)',
      ApiFailureKind.unknown => 'Terjadi kesalahan yang tidak dikenali',
    };
  }

  @override
  String toString() => 'ApiFailure(${kind.name}): $message';
}
