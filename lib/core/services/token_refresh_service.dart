import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:jwt_decode/jwt_decode.dart';

/// Service untuk proactive token refresh (sebelum token kadaluarsa).
/// 
/// Mengikuti spesifikasi arsitektur:
/// - Parse JWT claim 'exp' menggunakan jwt_decode
/// - Jadwalkan refresh beberapa saat sebelum token kadaluarsa (default 45 detik)
/// - Eksekusi refresh callback secara transparan tanpa mengganggu operator
class TokenRefreshService {
  Timer? _refreshTimer;
  String? _scheduledToken;
  bool _isRefreshing = false;
  
  /// Callback yang dipanggil saat waktu refresh tiba.
  /// Menghasilkan token baru, atau null jika gagal.
  Future<String?> Function()? onRefreshToken;

  /// Callback jika refresh gagal (misal untuk logout atau pemberitahuan).
  VoidCallback? onRefreshFailed;

  TokenRefreshService({
    this.onRefreshToken,
    this.onRefreshFailed,
  });

  /// Status apakah timer refresh sedang aktif
  bool get isScheduled => _refreshTimer?.isActive ?? false;

  /// Jadwalkan refresh berikutnya berdasarkan exp claim di dalam JWT token.
  /// 
  /// [token]: JWT token string
  /// [leadTime]: Durasi sebelum expired kapan refresh harus dijalankan
  void scheduleNextRefresh(
    String token, {
    Duration? leadTime,
  }) {
    cancel();

    if (token.isEmpty) {
      debugPrint('[TokenRefreshService] Token kosong, abaikan penjadwalan.');
      return;
    }

    _scheduledToken = token;

    try {
      final expiryDate = getExpiryDate(token);
      if (expiryDate == null) {
        debugPrint('[TokenRefreshService] Gagal membaca expiry date dari token.');
        return;
      }

      final now = DateTime.now();
      final effectiveLeadTime = leadTime ??
          const Duration(seconds: 45); // Sesuai spesifikasi Fase 1 (expTime - 45 detik)

      // Waktu kapan refresh harus ditembak
      final targetRefreshTime = expiryDate.subtract(effectiveLeadTime);
      final delay = targetRefreshTime.difference(now);

      if (delay.isNegative || delay.inSeconds <= 0) {
        if (isExpired(token)) {
          debugPrint('[TokenRefreshService] Token sudah kadaluarsa saat dijadwalkan.');
          onRefreshFailed?.call();
          return;
        }

        // Jika mendekati expired tapi belum lewat, trigger refresh asinkron
        debugPrint('[TokenRefreshService] Token dalam window lead time. Memicu refresh asinkron.');
        Timer.run(_executeRefresh);
        return;
      }

      debugPrint('[TokenRefreshService] Menjadwalkan refresh dalam ${delay.inMinutes} menit (${delay.inSeconds} detik).');
      _refreshTimer = Timer(delay, _executeRefresh);
    } catch (e) {
      debugPrint('[TokenRefreshService] Error saat parsing JWT atau penjadwalan: $e');
    }
  }

  /// Eksekusi refresh token dan jadwal ulang jika berhasil
  Future<void> _executeRefresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    cancel();

    if (onRefreshToken == null) {
      debugPrint('[TokenRefreshService] onRefreshToken callback tidak disetel.');
      _isRefreshing = false;
      return;
    }

    try {
      debugPrint('[TokenRefreshService] Menjalankan proactive token refresh...');
      final newToken = await onRefreshToken!();
      _isRefreshing = false;

      if (newToken != null && newToken.isNotEmpty) {
        if (newToken == _scheduledToken) {
          debugPrint('[TokenRefreshService] Token refresh menghasilkan token yang sama, menghentikan loop refresh.');
          return;
        }
        debugPrint('[TokenRefreshService] Token berhasil direfresh secara proaktif.');
        scheduleNextRefresh(newToken);
      } else {
        debugPrint('[TokenRefreshService] Token refresh gagal: token baru kosong/null.');
        onRefreshFailed?.call();
      }
    } catch (e) {
      _isRefreshing = false;
      debugPrint('[TokenRefreshService] Exception saat token refresh: $e');
      onRefreshFailed?.call();
    }
  }

  /// Batalkan timer yang sedang berjalan
  void cancel() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Ambil Expiry Date dari JWT token
  DateTime? getExpiryDate(String token) {
    try {
      return Jwt.getExpiryDate(token);
    } catch (e) {
      try {
        final payload = Jwt.parseJwt(token);
        if (payload.containsKey('exp')) {
          final exp = payload['exp'];
          if (exp is int) {
            return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          }
        }
      } catch (_) {}
      return null;
    }
  }

  /// Cek apakah token sudah expired
  bool isExpired(String token) {
    try {
      return Jwt.isExpired(token);
    } catch (_) {
      final exp = getExpiryDate(token);
      if (exp == null) return false;
      return DateTime.now().isAfter(exp);
    }
  }
}
