// File: token_jwt_state.dart
// State classes untuk TokenJwtCubit

/// Base state untuk token management
/// 
/// Menggunakan sealed class + subclass pattern untuk type-safe state
/// Sealed = tidak bisa diextend di file lain (hanya subclass di sini)
sealed class TokenJwtState {
  // Private constructor untuk seal class
  const TokenJwtState();

  /// Factory untuk create initial state
  /// 
  /// Digunakan saat Cubit di-initialize
  /// State: loading, tidak ada token, belum cek storage
  const factory TokenJwtState.initial() = _TokenJwtStateInitial;

  /// Factory untuk create authenticated state
  /// 
  /// [token]: JWT token string yang valid
  /// Digunakan setelah login sukses atau token loaded dari storage
  const factory TokenJwtState.authenticated(String token) = TokenJwtStateAuthenticated;

  /// Factory untuk create unauthenticated state
  /// 
  /// Tidak ada token — user belum login atau sudah logout
  /// Aplikasi harus show login screen
  const factory TokenJwtState.unauthenticated() = _TokenJwtStateUnauthenticated;

  /// Factory untuk create error state
  /// 
  /// [message]: Error message (misal "Token expired", "Hive error")
  /// Digunakan saat load/save/clear token gagal
  factory TokenJwtState.error(String message) = _TokenJwtStateError;
}

/// Initial state — sebelum cek storage
/// 
/// Digunakan saat app baru di-start
/// Cubit akan call loadToken() untuk transition ke authenticated/unauthenticated
class _TokenJwtStateInitial extends TokenJwtState {
  // Const constructor — immutable
  const _TokenJwtStateInitial();
}

/// Authenticated state — user sudah login, ada valid token
/// 
/// [token]: JWT token string dari backend
/// State ini berarti:
/// - User bisa akses protected routes
/// - Token akan di-inject ke API requests (Authorization header)
/// - AppBar tampilkan nama user (dari token claims atau /me endpoint)
class TokenJwtStateAuthenticated extends TokenJwtState {
  // JWT token value
  // Token ini akan di-pass ke ApiService.setToken() untuk API requests
  final String token;

  /// Constructor dengan token parameter
  /// 
  /// [token]: JWT token string
  const TokenJwtStateAuthenticated(this.token);

  /// Override == untuk compare dua state
  /// 
  /// Dua authenticated state sama jika token sama
  /// Useful untuk stream equality checks
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenJwtStateAuthenticated &&
          runtimeType == other.runtimeType &&
          token == other.token;

  /// Override hashCode untuk use di Map/Set
  @override
  int get hashCode => token.hashCode;
}

/// Unauthenticated state — tidak ada token, user belum/sudah login
/// 
/// Aplikasi harus show login screen
/// User tidak bisa akses protected routes
class _TokenJwtStateUnauthenticated extends TokenJwtState {
  // Const constructor — immutable
  const _TokenJwtStateUnauthenticated();
}

/// Error state — error saat load/save/clear token
/// 
/// [message]: Error message untuk di-show ke user (misal di snackbar)
class _TokenJwtStateError extends TokenJwtState {
  // Error message string
  // Bisa di-show ke user atau di-log untuk debugging
  final String message;

  /// Constructor dengan error message
  /// 
  /// [message]: Error message
  const _TokenJwtStateError(this.message);

  /// Override == untuk compare error states
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TokenJwtStateError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  /// Override hashCode
  @override
  int get hashCode => message.hashCode;
}

