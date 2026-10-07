// File: auth_repository.dart
// Repository untuk authentication endpoints (login, logout, me)

import '../../services/api_service.dart';
import '../dao/token_jwt_dao.dart';
import '../../config/api_endpoints.dart';

/// Response model untuk login endpoint
/// 
/// Backend return: { "token": "jwt_token_string", ... }
class LoginResponse {
  // JWT token dari backend
  // Disimpan ke TokenJwtDAO setelah login sukses
  final String token;
  
  // User ID dari backend (optional, untuk cek siapa yang login)
  final String? userId;
  
  // User name dari backend (optional)
  final String? name;

  /// Constructor
  LoginResponse({
    required this.token,
    this.userId,
    this.name,
  });

  /// Parse dari JSON response
  /// 
  /// Backend format: { "data": { "token": "...", "userId": "...", "name": "..." } }
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String? ?? '',
      userId: json['userId'] as String?,
      name: json['name'] as String?,
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() => {
    'token': token,
    'userId': userId,
    'name': name,
  };
}

/// Response model untuk me endpoint
/// 
/// Backend return: { "id": "...", "email": "...", "name": "...", ... }
class UserResponse {
  // User ID unique identifier
  final String id;
  
  // User email
  final String email;
  
  // User name untuk display di UI
  final String name;
  
  // User role (optional, untuk permission checking)
  final String? role;
  
  // User status (optional, active/inactive)
  final String? status;

  /// Constructor
  UserResponse({
    required this.id,
    required this.email,
    required this.name,
    this.role,
    this.status,
  });

  /// Parse dari JSON response
  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String?,
      status: json['status'] as String?,
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role,
    'status': status,
  };
}

/// Repository untuk authentication operations
/// 
/// Handle login, logout, dan me (get current user)
/// Layer antara BLoC dan data sources (API/Mock)
class AuthRepository {
  // Dependency injection: ApiService untuk API calls
  // ApiService handle interceptor, signing, encryption
  final ApiService _apiService;
  
  // Dependency injection: TokenJwtDAO untuk token storage
  // Token disimpan terenkripsi ke Hive
  final TokenJwtDAO _tokenDAO;

  /// Constructor dengan dependency injection
  /// 
  /// [_apiService]: Dio client dengan interceptor
  /// [_tokenDAO]: Hive token storage
  AuthRepository(this._apiService, this._tokenDAO);

  // ==================== LOGIN ENDPOINT ====================

  /// Login dengan username dan password
  /// 
  /// [username]: Email atau username
  /// [password]: Password plaintext (akan di-hash/encrypt oleh ApiService)
  /// 
  /// Returns: LoginResponse dengan JWT token
  /// Throws: Exception jika login gagal (wrong credentials, server error)
  /// 
  /// Flow:
  /// 1. Call /login endpoint (POST)
  /// 2. Backend validate credentials → return token
  /// 3. Token disimpan ke TokenJwtDAO (terenkripsi)
  /// 4. Token di-inject ke API interceptor (future requests)
  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      // Validate input
      if (username.isEmpty || password.isEmpty) {
        throw Exception('Username dan password tidak boleh kosong');
      }

      // Build request body
      // Format: { "username": "...", "password": "..." }
      final body = {
        'username': username,
        'password': password,
      };

      // Call /login endpoint via ApiService
      // ApiService handle:
      // - Encryption body (jika EnvConfig.isNeedEncrypt = true)
      // - HMAC-SHA256 signing (X-SIGNATURE header)
      // - Add headers (CHANNEL-CD, X-TIMESTAMP, Accept-Language)
      // - Decrypt response (jika encrypted)
      final response = await _apiService.post(
        ApiEndpoints.login,
        data: body,
      );

      // Parse response
      // Backend format: { "success": true, "data": { "token": "...", ... }, "message": "..." }
      // ApiService already decrypt jika encrypted
      final responseData = response.data as Map<String, dynamic>;
      
      // Check success flag
      final success = responseData['success'] as bool? ?? false;
      if (!success) {
        final message = responseData['message'] as String? ?? 'Login gagal';
        throw Exception(message);
      }

      // Extract data field
      // data = { "token": "...", "userId": "...", "name": "..." }
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Data tidak diterima dari server');
      }

      // Parse ke LoginResponse model
      final loginResponse = LoginResponse.fromJson(data);

      // Validate token tidak kosong
      if (loginResponse.token.isEmpty) {
        throw Exception('Token tidak diterima dari server');
      }

      // Simpan token ke TokenJwtDAO (terenkripsi)
      // Next request akan auto-inject token ke Authorization header
      await _tokenDAO.saveToken(loginResponse.token);

      // Set token ke ApiService interceptor
      // Future requests akan include Authorization: Bearer <token>
      _apiService.setToken(loginResponse.token);

      // Return LoginResponse
      // BLoC akan handle success state dan navigate ke home screen
      return loginResponse;
    } catch (e) {
      // Log error (di production gunakan logging service)
      print('Login error: $e');
      rethrow; // Re-throw untuk di-handle BLoC
    }
  }

  // ==================== LOGOUT ENDPOINT ====================

  /// Logout — invalidate token di backend
  /// 
  /// Throws: Exception jika logout gagal
  /// 
  /// Flow:
  /// 1. Get token dari TokenJwtDAO
  /// 2. Call /logout endpoint (POST) dengan token
  /// 3. Backend invalidate token
  /// 4. Delete token dari TokenJwtDAO
  /// 5. Clear interceptor token
  Future<void> logout() async {
    try {
      // Get current token dari storage
      // Token diperlukan untuk call /logout (server validate siapa yang logout)
      final token = _tokenDAO.getToken();

      if (token != null && token.isNotEmpty) {
        // Call /logout endpoint
        // ApiService akan auto-inject token ke Authorization header
        final response = await _apiService.post(
          ApiEndpoints.logout,
        );

        // Parse response
        final responseData = response.data as Map<String, dynamic>?;
        
        // Check success (opsional, bahkan jika gagal cleanup local token)
        final success = responseData?['success'] as bool? ?? false;
        if (!success) {
          print('Logout server response error: ${responseData?['message']}');
          // Continue cleanup local token meskipun server error
        }
      }

      // Delete token dari TokenJwtDAO (terenkripsi storage)
      await _tokenDAO.deleteToken();

      // Clear token dari ApiService interceptor
      // Future requests tidak akan include Authorization header
      _apiService.clearToken();

    } catch (e) {
      // Log error tapi tetap cleanup local storage
      print('Logout error: $e');
      
      // Ensure local cleanup
      await _tokenDAO.deleteToken();
      _apiService.clearToken();
      
      // Re-throw untuk BLoC tahu ada error
      rethrow;
    }
  }

  // ==================== ME ENDPOINT ====================

  /// Get current user info (me endpoint)
  /// 
  /// Returns: UserResponse dengan user details
  /// Throws: Exception jika call gagal (401 Unauthorized, server error)
  /// 
  /// Endpoints call:
  /// 1. GET /me
  /// 2. Token auto-inject dari interceptor (dari TokenJwtDAO)
  /// 3. Backend return user data
  /// 
  /// Use case:
  /// - App startup → verify token still valid
  /// - Refresh user data di home screen
  /// - Check user permission/role (dari role field)
  Future<UserResponse> me() async {
    try {
      // Get token dari storage
      // Jika tidak ada token, throw error (user belum login)
      final token = _tokenDAO.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan, silakan login ulang');
      }

      // Ensure token set di ApiService
      _apiService.setToken(token);

      // Call /me endpoint
      // GET request, token auto-inject
      final response = await _apiService.get(
        ApiEndpoints.me,
      );

      // Parse response
      // Backend format: { "success": true, "data": { "id": "...", "name": "...", ... }, "message": "..." }
      final responseData = response.data as Map<String, dynamic>;
      
      // Check success
      final success = responseData['success'] as bool? ?? false;
      if (!success) {
        final message = responseData['message'] as String? ?? 'Gagal ambil user data';
        throw Exception(message);
      }

      // Extract data field
      // data = { "id": "...", "email": "...", "name": "...", ... }
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Data user tidak diterima dari server');
      }

      // Parse ke UserResponse model
      final userResponse = UserResponse.fromJson(data);

      // Return user data
      return userResponse;
    } catch (e) {
      print('Me endpoint error: $e');
      rethrow;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Check apakah user sudah authenticated (ada token)
  /// 
  /// Returns: true jika token ada di storage, false jika belum
  bool isAuthenticated() {
    return _tokenDAO.hasToken();
  }

  /// Get current token
  /// 
  /// Returns: Token string atau null jika belum ada
  String? getCurrentToken() {
    return _tokenDAO.getToken();
  }
}
