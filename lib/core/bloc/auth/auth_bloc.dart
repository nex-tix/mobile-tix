// File: auth_bloc.dart
// BLoC untuk authentication flow (login, logout, auto-login)

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../token_jwt/token_jwt_cubit.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// AuthBloc mengelola seluruh proses otentikasi aplikasi
///
/// Responsibilities:
/// - Inisialisasi (cek token yang tersimpan)
/// - Menangani event login (username/password)
/// - Menangani logout
/// - Propagasi state ke UI (loading, success, failure)
///
/// Dependency injection:
/// - AuthRepository: berkomunikasi dengan backend (login, me, logout)
/// - TokenJwtCubit: mengelola state token global dan penyimpanan Hive
/// - ApiService: client Dio dengan interceptor (token injection)
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final TokenJwtCubit tokenCubit;
  final ApiService apiService;

  AuthBloc({
    required this.authRepository,
    required this.tokenCubit,
    required this.apiService,
  }) : super(const AuthInitial()) {
    // Event handlers
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  // ==================== AUTH CHECK ====================

  /// Cek apakah ada token di penyimpanan saat app start
  ///
  /// Emits:
  /// - AuthAuthenticated jika token valid
  /// - AuthUnauthenticated jika tidak ada atau invalid
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Load token dari TokenJwtCubit (Hive storage)
      final token = tokenCubit.getCurrentToken();

      if (token != null && token.isNotEmpty) {
        // Set token di ApiService interceptor untuk request selanjutnya
        apiService.setToken(token);
        // Emit authenticated state, UI dapat langsung navigasi ke home
        emit(const AuthAuthenticated());
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  // ==================== LOGIN ====================

  /// Handle login event
  ///
  /// Flow:
  /// 1. Emit AuthLoading (UI show progress)
  /// 2. Call AuthRepository.login(username, password)
  /// 3. Jika login sukses:
  ///    - Simpan token via TokenJwtCubit (encrypted Hive)
  ///    - Set token di ApiService (Authorization header)
  ///    - Emit AuthAuthenticated
  /// 4. Jika gagal: emit AuthFailure dengan message
  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await authRepository.login(
        username: event.username,
        password: event.password,
      );

      // Simpan token (sudah di‑save oleh AuthRepository, tapi kita set lagi untuk UI sync)
      tokenCubit.saveToken(response.token);
      apiService.setToken(response.token);

      emit(const AuthAuthenticated());
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  // ==================== LOGOUT ====================

  /// Handle logout event
  ///
  /// Flow:
  /// 1. Call AuthRepository.logout() (server invalidate + local cleanup)
  /// 2. Clear token di ApiService & TokenJwtCubit
  /// 3. Emit AuthUnauthenticated (UI kembali ke login screen)
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await authRepository.logout();
    } catch (_) {
      // ignore server error, still clear locally
    }
    // Clear token dari cubit dan interceptor
    tokenCubit.clearToken();
    apiService.clearToken();
    emit(const AuthUnauthenticated());
  }
}
