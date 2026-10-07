// File: token_jwt_cubit.dart
// Global state management untuk JWT token

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/dao/token_jwt_dao.dart';
import 'token_jwt_state.dart';

/// Cubit untuk manage JWT token lifecycle global
/// 
/// Responsibilities:
/// - Load token saat app startup
/// - Save token setelah login sukses
/// - Clear token saat logout
/// - Expose token state untuk dependency injection ke services
class TokenJwtCubit extends Cubit<TokenJwtState> {
  // Singleton instance DAO untuk akses encrypted storage
  final TokenJwtDAO _tokenDAO;

  /// Constructor dengan dependency injection TokenJwtDAO
  /// 
  /// [_tokenDAO]: DAO singleton untuk Hive storage
  TokenJwtCubit(this._tokenDAO) : super(const TokenJwtState.initial());

  /// Load token dari storage saat app startup
  /// 
  /// Dipanggil di main() sebelum app dijalankan
  /// Jika token ada dan valid, emit authenticated state
  /// Jika token tidak ada atau expired, emit unauthenticated state
  Future<void> loadToken() async {
    try {
      // Get token dari Hive storage (terenkripsi)
      // Ini check token yang sudah disimpan dari login sebelumnya
      final token = _tokenDAO.getToken();

      if (token != null && token.isNotEmpty) {
        // Token ditemukan — emit authenticated state dengan token
        // State ini digunakan untuk:
        // - Auto-set bearer token di API interceptor
        // - Protect routes (jika token ada, skip login screen)
        // - Inject token ke BLoC/service lainnya
        emit(TokenJwtState.authenticated(token));
      } else {
        // Token tidak ada atau kosong — user belum login
        // Emit unauthenticated state (aplikasi tampilkan login screen)
        emit(const TokenJwtState.unauthenticated());
      }
    } catch (e) {
      // Error saat load token (misal Hive corrupted)
      // Fallback ke unauthenticated state
      emit(TokenJwtState.error(e.toString()));
    }
  }

  /// Save token setelah login sukses
  /// 
  /// [token]: JWT token string dari backend
  /// 
  /// Disimpan ke Hive (terenkripsi) dan emit authenticated state
  /// Dipanggil dari auth_bloc setelah login API berhasil
  Future<void> saveToken(String token) async {
    try {
      // Validate token tidak kosong
      if (token.isEmpty) {
        emit(TokenJwtState.error('Token cannot be empty'));
        return;
      }

      // Simpan token ke Hive (auto-encrypt menggunakan EncryptionService key)
      // Token disimpan dalam box 'token_box' dengan key 'jwt_token'
      await _tokenDAO.saveToken(token);

      // Emit authenticated state dengan token yang baru disimpan
      // State ini akan trigger update di semua BLoC yang listen
      emit(TokenJwtState.authenticated(token));
    } catch (e) {
      // Error saat save token (misal Hive error)
      emit(TokenJwtState.error(e.toString()));
    }
  }

  /// Clear token saat logout
  /// 
  /// Dipanggil saat user tap logout button
  /// Delete token dari storage dan emit unauthenticated state
  Future<void> clearToken() async {
    try {
      // Hapus token dari Hive storage
      // Setelah ini, next app startup tidak ada token lagi
      await _tokenDAO.deleteToken();

      // Emit unauthenticated state
      // Aplikasi auto-navigate ke login screen
      emit(const TokenJwtState.unauthenticated());
    } catch (e) {
      // Error saat clear token
      emit(TokenJwtState.error(e.toString()));
    }
  }

  /// Get current token value
  /// 
  /// Returns: Token string atau null jika tidak ada
  /// 
  /// Convenience method untuk akses token dari state
  /// Contoh: final token = tokenJwtCubit.getCurrentToken();
  String? getCurrentToken() {
    // Check state type
    // Jika state authenticated, return token value
    // Jika unauthenticated atau error, return null
    if (state is TokenJwtStateAuthenticated) {
      return (state as TokenJwtStateAuthenticated).token;
    }
    return null;
  }

  /// Check apakah user sudah authenticated
  /// 
  /// Returns: true jika token ada dan valid, false jika tidak
  /// 
  /// Gampang check tanpa perlu cast state
  bool isAuthenticated() {
    // Simple check: state is authenticated?
    return state is TokenJwtStateAuthenticated;
  }
}

