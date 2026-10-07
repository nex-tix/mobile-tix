// File: checkpoint_dao.dart
// DAO untuk cache checkpoint list dari API

import 'package:hive/hive.dart';

/// DAO untuk menyimpan & mengambil checkpoint (gate/pintu) list
/// 
/// Features:
/// - Cache checkpoint list hasil dari GET /checkpoints
/// - TTL-based cache invalidation (12 jam)
/// - Singleton pattern
class CheckpointDAO {
  // Nama box Hive untuk cache checkpoints
  static const String _boxName = 'checkpoint_box';
  
  // Key untuk menyimpan array checkpoint
  static const String _checkpointsKey = 'checkpoints_list';
  
  // Key untuk menyimpan last update timestamp
  static const String _lastUpdateKey = 'last_update';

  // Key untuk checkpoint yang sedang aktif dipilih petugas
  // Dipisah dari cache list supaya clear cache tidak menghapus pilihan gate
  static const String _activeKey = 'active_checkpoint';

  // Cache TTL = 12 jam (43200 detik)
  static const Duration _cacheTtl = Duration(hours: 12);

  // Singleton instance
  static final CheckpointDAO _instance = CheckpointDAO._internal();
  factory CheckpointDAO() => _instance;
  CheckpointDAO._internal();

  // Reference ke Hive box
  late Box<dynamic> _checkpointBox;

  /// Initialize DAO — buka Hive box
  Future<void> initialize() async {
    try {
      // Buka box untuk checkpoint cache
      // Tipe dynamic karena menyimpan mixed data (List dan DateTime)
      _checkpointBox = await Hive.openBox(_boxName);
    } catch (e) {
      throw Exception('Failed to initialize CheckpointDAO: $e');
    }
  }

  /// Simpan checkpoint list ke cache
  /// 
  /// [checkpoints]: List<Map> berisi checkpoint data dari API
  /// Otomatis update timestamp last_update saat disimpan
  Future<void> saveCheckpoints(List<Map<String, dynamic>> checkpoints) async {
    try {
      // Simpan array checkpoint sebagai JSON string
      // Hive box<dynamic> bisa simpan berbagai tipe termasuk List
      await _checkpointBox.put(
        _checkpointsKey,
        checkpoints, // Hive auto-serialize List ke JSON format
      );
      
      // Update timestamp kapan checkpoint di-save
      // Ini untuk tracking cache age
      await _checkpointBox.put(
        _lastUpdateKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      throw Exception('Failed to save checkpoints: $e');
    }
  }

  /// Ambil checkpoint list dari cache
  /// 
  /// Returns: List<Map> checkpoint cache, null jika tidak ada
  /// Hive auto-deserialize JSON kembali ke List
  List<Map<String, dynamic>>? getCheckpoints() {
    try {
      // Get value — return null jika key tidak ada
      final data = _checkpointBox.get(_checkpointsKey);
      
      // Type casting — convert dari dynamic ke typed List
      if (data is List) {
        // Cast List ke List<Map<String, dynamic>>
        return List<Map<String, dynamic>>.from(data);
      }
      
      return null;
    } catch (e) {
      print('Error getting checkpoints: $e');
      return null;
    }
  }

  /// Check apakah cache checkpoint masih fresh (belum expired)
  /// 
  /// Returns: true jika cache masih valid, false jika sudah expired
  /// Cache invalidate otomatis setelah 12 jam
  bool isCacheValid() {
    try {
      // Get last update timestamp dari box
      final lastUpdateStr = _checkpointBox.get(_lastUpdateKey) as String?;
      
      // Jika tidak ada timestamp, cache tidak valid
      if (lastUpdateStr == null) return false;
      
      // Parse timestamp ke DateTime
      final lastUpdate = DateTime.parse(lastUpdateStr);
      
      // Hitung berapa lama cache sudah disimpan
      final now = DateTime.now();
      final cacheAge = now.difference(lastUpdate);
      
      // Check apakah cache age <= TTL (12 jam)
      // Jika lebih dari 12 jam, cache expired
      return cacheAge <= _cacheTtl;
    } catch (e) {
      print('Error checking cache validity: $e');
      return false;
    }
  }

  /// Hapus checkpoint cache
  /// 
  /// Digunakan untuk force-refresh data dari API
  Future<void> clear() async {
    try {
      // Delete kedua keys (checkpoint dan last_update)
      await _checkpointBox.delete(_checkpointsKey);
      await _checkpointBox.delete(_lastUpdateKey);
    } catch (e) {
      throw Exception('Failed to clear checkpoint cache: $e');
    }
  }

  // ==================== ACTIVE CHECKPOINT (Fase 3) ====================

  /// Simpan checkpoint/gate yang aktif dipilih petugas
  /// 
  /// [checkpoint]: data gate aktif dalam bentuk Map (hasil toJson())
  /// 
  /// Disimpan di key terpisah dari cache list supaya pilihan petugas tetap
  /// bertahan walau cache checkpoint di-refresh. Dipanggil saat petugas
  /// memilih gate di halaman checkpoint picker.
  Future<void> saveCheckpoint(Map<String, dynamic> checkpoint) async {
    try {
      await _checkpointBox.put(_activeKey, checkpoint);
    } catch (e) {
      throw Exception('Failed to save active checkpoint: $e');
    }
  }

  /// Ambil checkpoint aktif yang tersimpan
  /// 
  /// Returns: Map checkpoint aktif, atau null jika petugas belum memilih gate
  /// 
  /// Dipakai saat app restart — kalau ada nilai, app langsung masuk mode scan
  /// tanpa meminta petugas memilih gate lagi.
  Map<String, dynamic>? getActiveCheckpoint() {
    try {
      final data = _checkpointBox.get(_activeKey);

      // Type casting — Hive menyimpan Map sebagai dynamic
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return null;
    } catch (e) {
      print('Error getting active checkpoint: $e');
      return null;
    }
  }

  /// Check apakah ada checkpoint aktif tersimpan
  /// 
  /// Returns: true jika petugas sudah punya gate aktif di storage
  bool hasActiveCheckpoint() {
    try {
      return _checkpointBox.containsKey(_activeKey);
    } catch (e) {
      return false;
    }
  }

  /// Hapus checkpoint aktif dari storage
  /// 
  /// Dipakai saat logout — gate pilihan tidak boleh tertinggal untuk
  /// sesi petugas berikutnya di perangkat yang sama.
  Future<void> clearActiveCheckpoint() async {
    try {
      await _checkpointBox.delete(_activeKey);
    } catch (e) {
      throw Exception('Failed to clear active checkpoint: $e');
    }
  }

  /// Close Hive box
  Future<void> close() async {
    try {
      await _checkpointBox.close();
    } catch (e) {
      print('Error closing checkpoint box: $e');
    }
  }
}

