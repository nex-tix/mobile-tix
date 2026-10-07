import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';
import 'encryption_service.dart';
import 'signature_service.dart';
import 'mock_api_adapter.dart';

/// Enhanced API Service dengan interceptor lengkap
/// 
/// Sesuai spesifikasi Fase 1 arsitektur:
/// - Request Interceptor: Auto inject headers, SHA256 body hash, HMAC signing, AES-CBC encryption
/// - Response Interceptor: Auto decrypt payload jika terenkripsi
/// - Error Interceptor: Menangkap HTTP 401 -> 1x token refresh & retry request asli
/// - Mock API Interceptor: Simulasi response jika EnvConfig.useMockApi aktif
class ApiService {
  late final Dio _dio;
  String? _token;

  /// Callback untuk refresh token ketika menerima HTTP 401
  Future<String?> Function()? onRefreshToken;

  /// Callback ketika token refresh gagal (sesi habis / force logout)
  VoidCallback? onSessionExpired;

  bool _isRefreshing = false;

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

    // Mock API interceptor dijalankan sebelum network jika diaktifkan
    if (EnvConfig.useMockApi) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: _handleMockRequest,
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  Dio get dio => _dio;

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

  // ==================== MOCK API INTERCEPTOR ====================

  Future<void> _handleMockRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final adapter = MockApiAdapter();
    final path = options.path;

    try {
      Map<String, dynamic> body = {};
      if (options.data != null) {
        if (options.data is Map) {
          body = Map<String, dynamic>.from(options.data as Map);
        } else if (options.data is String) {
          try {
            body = json.decode(options.data as String) as Map<String, dynamic>;
          } catch (_) {}
        }
      }

      if (path.endsWith('/login')) {
        final res = await adapter.login(
          username: body['username']?.toString() ?? '',
          password: body['password']?.toString() ?? '',
          checkpoint: body['checkpoint']?.toString() ?? 'Gate A',
        );
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: res.success ? 200 : 401,
          data: res.toJson(),
        ));
      }

      if (path.endsWith('/logout')) {
        final res = await adapter.logout();
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: res.toJson(),
        ));
      }

      if (path.endsWith('/me')) {
        final res = await adapter.getCurrentUser();
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: res.toJson(),
        ));
      }

      if (path.endsWith('/checkpoints')) {
        final res = await adapter.getCheckpoints();
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: res.toJson(),
        ));
      }

      if (path.endsWith('/ticket/check')) {
        final res = await adapter.checkTicket(
          ticketCode: body['ticket_code']?.toString() ??
              body['ticketCode']?.toString() ??
              '',
        );
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: res.success ? 200 : 400,
          data: res.toJson(),
        ));
      }

      if (path.endsWith('/ticket/validate-and-checkin')) {
        final res = await adapter.validateAndCheckIn(
          ticketCode: body['ticket_code']?.toString() ??
              body['ticketCode']?.toString() ??
              '',
          checkpoint: body['checkpoint']?.toString() ?? 'Gate A',
        );
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: res.success ? 200 : 400,
          data: res.toJson(),
        ));
      }

      if (path.endsWith('/dashboard/summary')) {
        final res = await adapter.getDashboardSummary(
          date: options.queryParameters['date']?.toString(),
        );
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: res.toJson(),
        ));
      }

      if (path.endsWith('/ticket/history')) {
        final page = int.tryParse(options.queryParameters['page']?.toString() ?? '1') ?? 1;
        final limit = int.tryParse(options.queryParameters['limit']?.toString() ?? '20') ?? 20;
        final res = await adapter.getTicketHistory(
          page: page,
          limit: limit,
          date: options.queryParameters['date']?.toString(),
          checkpoint: options.queryParameters['checkpoint']?.toString(),
          status: options.queryParameters['status']?.toString(),
        );
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: res.toJson(),
        ));
      }
    } catch (e) {
      debugPrint('[ApiService] Mock handler error: $e');
    }

    handler.next(options);
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
            ? options.data as String
            : json.encode(options.data);

        // Hash body dengan SHA256
        hashedBody = SignatureService.hashBody(bodyString);

        // Encrypt body jika enabled
        if (EnvConfig.isNeedEncrypt) {
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
    // Tangkap 401 Unauthorized → coba 1x auto-refresh token
    if (err.response?.statusCode == 401 && onRefreshToken != null && !_isRefreshing) {
      _isRefreshing = true;
      try {
        debugPrint('[ApiService] 401 Unauthorized terdeteksi. Mencoba auto-refresh token...');
        final newToken = await onRefreshToken!();
        _isRefreshing = false;

        if (newToken != null && newToken.isNotEmpty) {
          debugPrint('[ApiService] Refresh berhasil, retry request original...');
          setToken(newToken);

          // Clone options dan retry request
          final reqOptions = err.requestOptions;
          reqOptions.headers['Authorization'] = 'Bearer $newToken';

          final response = await _dio.fetch(reqOptions);
          return handler.resolve(response);
        } else {
          debugPrint('[ApiService] Refresh gagal, trigger session expired.');
          onSessionExpired?.call();
        }
      } catch (e) {
        _isRefreshing = false;
        debugPrint('[ApiService] Exception saat 401 auto-refresh: $e');
        onSessionExpired?.call();
      }
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
