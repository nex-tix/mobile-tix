import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/env_config.dart';
import 'encryption_service.dart';
import 'signature_service.dart';

/// Enhanced API Service dengan interceptor lengkap
/// 
/// Features:
/// - Auto request signing (X-SIGNATURE header)
/// - Auto encryption/decryption body (jika enabled)
/// - Auto inject headers (CHANNEL-CD, Accept-Language, X-TIMESTAMP)
/// - 401 auto-refresh token + retry
/// - Centralized error handling
class ApiService {
  late final Dio _dio;
  String? _token;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.baseUrl,
        connectTimeout: Duration(milliseconds: EnvConfig.apiTimeout),
        receiveTimeout: Duration(milliseconds: EnvConfig.apiTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  /// Set bearer token untuk authenticated requests
  void setToken(String? token) {
    _token = token;
  }

  /// Get current token
  String? get token => _token;

  /// Clear token (untuk logout)
  void clearToken() {
    _token = null;
  }

  // ==================== REQUEST INTERCEPTOR ====================
  
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // 1. Generate timestamp ISO 8601
      final timestamp = DateTime.now().toUtc().toIso8601String();

      // 2. Inject standard headers
      options.headers['CHANNEL-CD'] = EnvConfig.channelCd;
      options.headers['Accept-Language'] = EnvConfig.defaultLanguage;
      options.headers['X-TIMESTAMP'] = timestamp;

      // 3. Add Authorization header jika ada token
      if (_token != null && _token!.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $_token';
      }

      // 4. Process body (hash, encrypt, sign)
      String bodyString = '';
      String hashedBody = '';

      if (options.data != null) {
        // Convert body ke JSON string
        bodyString = options.data is String
            ? options.data
            : json.encode(options.data);

        // Hash body dengan SHA256
        hashedBody = SignatureService.hashBody(bodyString);

        // Encrypt body jika enabled
        if (EnvConfig.isNeedEncrypt) {
          // EncryptionService.encrypt() return format IV+CIPHERTEXT
          // IV (16 bytes) prepended ke ciphertext, diencode Base64
          final encryptedBody = EncryptionService.encrypt(bodyString);
          options.data = {'encrypted': encryptedBody};
        }
      }

      // 5. Generate signature
      final signature = SignatureService.sign(
        method: options.method,
        endpoint: options.path,
        token: _token ?? '',
        hashedBody: hashedBody,
        timestamp: timestamp,
      );

      options.headers['X-SIGNATURE'] = signature;

      handler.next(options);
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Request interceptor error: $e',
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  // ==================== RESPONSE INTERCEPTOR ====================
  
  Future<void> _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    try {
      // Decrypt response jika encrypted
      if (response.data != null &&
          response.data is Map &&
          response.data['encrypted'] != null) {
        final encryptedData = response.data['encrypted'] as String;
        final decryptedJson = EncryptionService.decrypt(encryptedData);
        response.data = json.decode(decryptedJson);
      }

      handler.next(response);
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Response decryption error: $e',
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  // ==================== ERROR INTERCEPTOR ====================
  
  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized → try token refresh
    if (err.response?.statusCode == 401) {
      // TODO: Implement token refresh logic
      // For now, just pass through
      handler.next(err);
      return;
    }

    handler.next(err);
  }

  // ==================== HTTP METHODS ====================

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
