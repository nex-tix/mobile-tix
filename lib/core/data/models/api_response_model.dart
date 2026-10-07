// File: api_response_model.dart
// Generic API Response model untuk semua endpoint

/// Generic response wrapper untuk semua API responses
/// Setiap response dari backend punya format: {"success": bool, "data": T, "message": string, "timestamp": string}
class ApiResponse<T> {
  // Flag status sukses/gagal response
  final bool success;
  
  // Actual data payload (generic type T bisa Login, Checkpoint, Ticket, dll)
  final T? data;
  
  // Error/info message dari backend
  final String message;
  
  // Timestamp kapan response dibuat (ISO 8601 format)
  final String timestamp;

  /// Constructor dengan semua parameter required
  ApiResponse({
    required this.success,
    required this.data,
    required this.message,
    required this.timestamp,
  });

  /// Factory constructor untuk create success response
  /// Ini convenience method supaya gampang buat response sukses
  factory ApiResponse.success({
    required T data,
    String message = 'Success',
  }) {
    // Ambil current timestamp UTC dalam format ISO 8601
    final now = DateTime.now().toUtc().toIso8601String();
    
    // Return instance dengan success = true
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      timestamp: now,
    );
  }

  /// Factory constructor untuk create error response
  /// Ini convenience method supaya gampang buat response error
  factory ApiResponse.error({
    String message = 'Error',
  }) {
    // Ambil current timestamp UTC dalam format ISO 8601
    final now = DateTime.now().toUtc().toIso8601String();
    
    // Return instance dengan success = false dan data = null
    return ApiResponse(
      success: false,
      data: null,
      message: message,
      timestamp: now,
    );
  }

  /// Convert API response to JSON format (untuk simpan cache atau debug)
  /// Returns: Map dengan struktur sama seperti backend response
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'message': message,
      'timestamp': timestamp,
    };
  }
}

