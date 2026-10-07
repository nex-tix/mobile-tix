// File: auth_event.dart
// Event definitions untuk AuthBloc

/// Base class untuk semua auth events
abstract class AuthEvent {
  const AuthEvent();
}

/// Event untuk meminta cek status otentikasi saat app start
/// 
/// Dipanggil di main.dart setelah inisialisasi BLoC
/// Contoh: context.read<AuthBloc>().add(const AuthCheckRequested());
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Event untuk submit login form
/// 
/// [username]: Email atau username
/// [password]: Password plaintext
/// 
/// Contoh: context.read<AuthBloc>().add(LoginSubmitted(
///   username: 'user@example.com',
///   password: 'password123',
/// ));
class LoginSubmitted extends AuthEvent {
  final String username;
  final String password;

  const LoginSubmitted({
    required this.username,
    required this.password,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginSubmitted &&
          runtimeType == other.runtimeType &&
          username == other.username &&
          password == other.password;

  @override
  int get hashCode => Object.hash(runtimeType, username, password);
}

/// Event untuk logout
/// 
/// Contoh: context.read<AuthBloc>().add(const LogoutRequested());
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}