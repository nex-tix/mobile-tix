/// Response model wrapper untuk API responses yang uniform.
///
/// Backend mengembalikan JSON dengan struktur standar:
/// { "success": bool, "data": T|null, "message": String|null, "errors": Map|null }
/// Wrapper ini mem-parsing response ke model yang konsumsi oleh seluruh app.
class ApiResponse<T> {
  /// Status keberhasilan request
  final bool success;

  /// Pesan dari backend (bisa null jika success=true tanpa message)
  final String? message;

  /// Data payload dari response
  final T? data;

  /// Map error detail (bisa berisi validation errors atau error sistem)
  final Map<String, dynamic>? errors;

  /// Constructor utama
  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });

  /// Factory: parse dari JSON response backend
  ///
  /// [fromJsonT]: fungsi konversi json['data'] → T (misal: LoginResponse.fromJson)
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      errors: json['errors'] is Map<String, dynamic>
          ? json['errors'] as Map<String, dynamic>
          : null,
    );
  }

  /// Convenience: apakah response gagal (success false)
  bool get isFailure => !success;

  /// Convenience: apakah response sukses dengan data
  bool get hasData => success && data != null;

  /// Convenience: apakah response sukses tanpa data
  bool get successWithoutData => success && data == null;
}