// File: auth_state.dart
// State definitions untuk AuthBloc

/// Base class untuk semua auth states
abstract class AuthState {
  const AuthState();
}

/// Initial state — sebelum cek token
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state — proses login/cek token berjalan
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state — user sudah login, token valid
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}

/// Unauthenticated state — tidak ada token atau token expired
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Error/failure state — login gagal atau error
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}