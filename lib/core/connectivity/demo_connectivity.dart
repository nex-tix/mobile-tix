import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../config/env_config.dart';
import 'connectivity_monitor.dart';

/// Dynamic connectivity monitor with real signal detection.
///
/// Fitur:
/// - Otomatis mendeteksi status sinyal via `connectivity_plus`
/// - Memverifikasi konektivitas internet aktif (DNS/IP lookup)
/// - Menyiarkan perubahan status via [onlineChanges], [onConnectionLost], dan [onConnectionRestored]
/// - Tidak dapat di-toggle manual (murni tergantung kondisi sinyal perangkat)
/// - Menyediakan fungsi [checkConnection] untuk mencari sinyal kembali saat offline
class DemoConnectivity extends ChangeNotifier implements ConnectivityMonitor {
  DemoConnectivity({
    bool? online,
    bool enableRealMonitoring = true,
  }) : _online = online ?? true {
    if (enableRealMonitoring) {
      _initRealMonitoring();
    }
  }

  bool _online;
  bool _isChecking = false;
  bool _isDisposed = false;

  final StreamController<bool> _changes = StreamController<bool>.broadcast();
  final StreamController<void> _lostStream = StreamController<void>.broadcast();
  final StreamController<void> _restoredStream = StreamController<void>.broadcast();

  StreamSubscription? _subscription;
  final Connectivity _connectivity = Connectivity();

  bool get online => _online;
  bool get offline => !_online;
  bool get isChecking => _isChecking;

  @override
  bool get isOnline => _online;

  @override
  Stream<bool> get onlineChanges => _changes.stream;

  /// Dipanggil saat koneksi tiba-tiba putus dari online ke offline
  Stream<void> get onConnectionLost => _lostStream.stream;

  /// Dipanggil saat koneksi pulih kembali dari offline ke online
  Stream<void> get onConnectionRestored => _restoredStream.stream;

  void _initRealMonitoring() {
    try {
      _subscription = _connectivity.onConnectivityChanged.listen(
        (results) {
          _evaluateConnectivity(results);
        },
        onError: (err) {
          debugPrint('[Connectivity] Stream error: $err');
        },
      );
      // Pengecekan awal saat inisialisasi
      checkConnection();
    } catch (e) {
      debugPrint('[Connectivity] Platform monitoring not available (test mode): $e');
    }
  }

  Future<void> _evaluateConnectivity(List<ConnectivityResult> results) async {
    if (_isDisposed) return;
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      setOnline(false);
      return;
    }
    // Jika ada sinyal wifi/seluler, verifikasi internet
    final hasNet = await _testInternet();
    if (_isDisposed) return;
    setOnline(hasNet);
  }

  /// Cek sinyal internet secara aktif (bisa dipanggil tombol refresh)
  Future<bool> checkConnection() async {
    if (_isDisposed || _isChecking) return _online;
    _isChecking = true;
    if (!_isDisposed) notifyListeners();

    try {
      final results = await _connectivity.checkConnectivity();
      if (_isDisposed) return _online;
      if (results.contains(ConnectivityResult.none) || results.isEmpty) {
        setOnline(false);
      } else {
        final hasNet = await _testInternet();
        if (_isDisposed) return _online;
        setOnline(hasNet);
      }
    } catch (e) {
      debugPrint('[Connectivity] Error checking connectivity: $e');
    } finally {
      _isChecking = false;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
    return _online;
  }

  Future<bool> _testInternet() async {
    if (kIsWeb) return true;
    try {
      final res = await InternetAddress.lookup('8.8.8.8')
          .timeout(const Duration(seconds: 3));
      if (res.isNotEmpty && res[0].rawAddress.isNotEmpty) return true;
    } catch (_) {}

    try {
      final host = Uri.tryParse(EnvConfig.baseUrl)?.host;
      if (host != null && host.isNotEmpty) {
        final res = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 3));
        if (res.isNotEmpty && res[0].rawAddress.isNotEmpty) return true;
      }
    } catch (_) {}

    return false;
  }

  /// Update status online/offline
  void setOnline(bool value) {
    if (_isDisposed || _online == value) return;
    final wasOnline = _online;
    _online = value;
    if (!_isDisposed) {
      _changes.add(_online);
      if (wasOnline && !_online) {
        _lostStream.add(null);
      } else if (!wasOnline && _online) {
        _restoredStream.add(null);
      }
      notifyListeners();
    }
  }

  /// Toggle manual dinonaktifkan (diarahkan untuk mencari sinyal / refresh)
  void toggle() => checkConnection();

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    _changes.close();
    _lostStream.close();
    _restoredStream.close();
    super.dispose();
  }
}
