import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

/// Service untuk idle timer & auto logout jika tidak ada aktivitas operator.
/// 
/// Mengikuti spesifikasi arsitektur Fase 1:
/// - Default idle: 5 menit (atau dari EnvConfig)
/// - Warning timer: 1 menit sebelum forced logout
/// - Memberikan callback untuk menampilkan warning dialog & eksekusi logout
class AutoLogoutService {
  final Duration idleDuration;
  final Duration warningDuration;

  Timer? _idleTimer;
  Timer? _warningTimer;

  bool _isWarningActive = false;
  bool _isEnabled = true;

  /// Callback ketika warning harus ditampilkan ke operator
  VoidCallback? onShowWarning;

  /// Callback ketika dialog warning harus ditutup
  VoidCallback? onDismissWarning;

  /// Callback ketika waktu habis dan app harus force logout
  VoidCallback? onForceLogout;

  /// Callback opsional saat operator memilih "Tetap Masuk"
  Future<void> Function()? onStayLoggedIn;

  AutoLogoutService({
    Duration? idleDuration,
    Duration? warningDuration,
    this.onShowWarning,
    this.onDismissWarning,
    this.onForceLogout,
    this.onStayLoggedIn,
    bool? isEnabled,
  })  : idleDuration = idleDuration ??
            Duration(minutes: EnvConfig.autoLogoutIdleMinutes),
        warningDuration = warningDuration ??
            Duration(seconds: EnvConfig.autoLogoutWarningSeconds),
        _isEnabled = isEnabled ?? EnvConfig.enableAutoLogout;

  bool get isWarningActive => _isWarningActive;
  bool get isEnabled => _isEnabled;

  /// Aktifkan atau nonaktifkan service auto-logout
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stop();
    } else {
      resetTimer();
    }
  }

  /// Mulai timer atau reset timer aktivitas operator
  void resetTimer() {
    if (!_isEnabled) return;

    _idleTimer?.cancel();
    _warningTimer?.cancel();

    if (_isWarningActive) {
      _isWarningActive = false;
      onDismissWarning?.call();
    }

    final warningLeadTime = idleDuration > warningDuration
        ? idleDuration - warningDuration
        : idleDuration;

    _idleTimer = Timer(warningLeadTime, _triggerWarning);
  }

  /// Menampilkan warning kepada operator
  void _triggerWarning() {
    if (!_isEnabled) return;
    _isWarningActive = true;
    debugPrint('[AutoLogoutService] Idle timeout tercapai. Menampilkan warning dialog.');
    onShowWarning?.call();

    // Mulai countdown peringatan sebelum force logout
    _warningTimer = Timer(warningDuration, forceLogout);
  }

  /// Operator memilih "Tetap Masuk"
  Future<void> stayLoggedIn() async {
    debugPrint('[AutoLogoutService] Operator memilih tetap masuk.');
    resetTimer();
    if (onStayLoggedIn != null) {
      try {
        await onStayLoggedIn!();
      } catch (e) {
        debugPrint('[AutoLogoutService] Error di onStayLoggedIn: $e');
      }
    }
  }

  /// Eksekusi force logout
  void forceLogout() {
    debugPrint('[AutoLogoutService] Waktu peringatan habis. Melakukan force logout.');
    stop();
    onForceLogout?.call();
  }

  /// Hentikan semua timer (misal saat operator sudah di halaman login atau logout manual)
  void stop() {
    _idleTimer?.cancel();
    _warningTimer?.cancel();
    _idleTimer = null;
    _warningTimer = null;
    if (_isWarningActive) {
      _isWarningActive = false;
      onDismissWarning?.call();
    }
  }
}
