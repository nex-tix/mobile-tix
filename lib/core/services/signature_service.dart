// File: signature_service.dart
// HMAC-SHA256 request signature service
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../config/env_config.dart';

/// Request signature service menggunakan HMAC-SHA256
/// 
/// Format base string: METHOD|ENDPOINT|[TOKEN]|HASHED_BODY|TIMESTAMP
/// Output: Base64-encoded HMAC-SHA256 signature
class SignatureService {
  const SignatureService._();

  /// Generate signature untuk HTTP request
  /// 
  /// [method]: HTTP method (GET, POST, PUT, DELETE)
  /// [endpoint]: API endpoint path (e.g., /login, /ticket/check)
  /// [token]: Bearer token (kosong string jika belum login)
  /// [hashedBody]: SHA256 hash dari request body JSON (hex string)
  /// [timestamp]: ISO 8601 timestamp (e.g., 2026-10-07T05:29:39.716Z)
  /// 
  /// Returns: Base64-encoded signature untuk header X-SIGNATURE
  static String sign({
    required String method,
    required String endpoint,
    required String token,
    required String hashedBody,
    required String timestamp,
  }) {
    // Base string format: METHOD|ENDPOINT|[TOKEN]|HASHED_BODY|TIMESTAMP
    final baseString = '$method|$endpoint|$token|$hashedBody|$timestamp';
    
    // HMAC-SHA256
    final key = utf8.encode(EnvConfig.signatureSecret);
    final bytes = utf8.encode(baseString);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    
    // Base64 encode
    return base64.encode(digest.bytes);
  }

  /// Hash request body dengan SHA256
  /// 
  /// Returns: Hex-encoded SHA256 hash
  static String hashBody(String body) {
    if (body.isEmpty) return '';
    
    final bytes = utf8.encode(body);
    final digest = sha256.convert(bytes);
    return digest.toString(); // hex string
  }

  /// Convenience method untuk sign request dengan body langsung
  /// (akan di-hash otomatis)
  static String signRequest({
    required String method,
    required String endpoint,
    required String token,
    required String body,
    required String timestamp,
  }) {
    final hashedBody = hashBody(body);
    return sign(
      method: method,
      endpoint: endpoint,
      token: token,
      hashedBody: hashedBody,
      timestamp: timestamp,
    );
  }
}

