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

  // Reference ke Hive box (lazy / nullable)
  Box<dynamic>? _checkpointBox;

  bool get isInitialized => _checkpointBox?.isOpen ?? false;

  /// Helper untuk memastikan box sudah terbuka
  Future<Box<dynamic>> _getBox() async {
    if (_checkpointBox != null && _checkpointBox!.isOpen) {
      return _checkpointBox!;
    }
    _checkpointBox = await Hive.openBox(_boxName);
    return _checkpointBox!;
  }

  /// Initialize DAO — buka Hive box
  Future<void> initialize() async {
    try {
      await _getBox();
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
      final box = await _getBox();
      await box.put(_checkpointsKey, checkpoints);
      await box.put(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      throw Exception('Failed to save checkpoints: $e');
    }
  }

  /// Ambil checkpoint list dari cache
  /// 
  /// Returns: List<Map> checkpoint cache, null jika tidak ada
  List<Map<String, dynamic>>? getCheckpoints() {
    try {
      final box = _checkpointBox;
      if (box == null || !box.isOpen) return null;

      final data = box.get(_checkpointsKey);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check apakah cache checkpoint masih fresh (belum expired)
  /// 
  /// Returns: true jika cache masih valid, false jika sudah expired
  bool isCacheValid() {
    try {
      final box = _checkpointBox;
      if (box == null || !box.isOpen) return false;

      final lastUpdateStr = box.get(_lastUpdateKey) as String?;
      if (lastUpdateStr == null) return false;

      final lastUpdate = DateTime.parse(lastUpdateStr);
      final now = DateTime.now();
      final cacheAge = now.difference(lastUpdate);

      return cacheAge <= _cacheTtl;
    } catch (e) {
      return false;
    }
  }

  /// Hapus checkpoint cache
  /// 
  /// Digunakan untuk force-refresh data dari API
  Future<void> clear() async {
    try {
      final box = await _getBox();
      await box.delete(_checkpointsKey);
      await box.delete(_lastUpdateKey);
    } catch (e) {
      throw Exception('Failed to clear checkpoint cache: $e');
    }
  }

  // ==================== ACTIVE CHECKPOINT (Fase 3) ====================

  /// Simpan checkpoint/gate yang aktif dipilih petugas
  /// 
  /// [checkpoint]: data gate aktif dalam bentuk Map (hasil toJson())
  Future<void> saveCheckpoint(Map<String, dynamic> checkpoint) async {
    try {
      final box = await _getBox();
      await box.put(_activeKey, checkpoint);
    } catch (e) {
      throw Exception('Failed to save active checkpoint: $e');
    }
  }

  /// Ambil checkpoint aktif yang tersimpan
  /// 
  /// Returns: Map checkpoint aktif, atau null jika petugas belum memilih gate
  Map<String, dynamic>? getActiveCheckpoint() {
    try {
      final box = _checkpointBox;
      if (box == null || !box.isOpen) return null;

      final data = box.get(_activeKey);
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check apakah ada checkpoint aktif tersimpan
  /// 
  /// Returns: true jika petugas sudah punya gate aktif di storage
  bool hasActiveCheckpoint() {
    try {
      final box = _checkpointBox;
      if (box == null || !box.isOpen) return false;
      return box.containsKey(_activeKey);
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
      final box = await _getBox();
      await box.delete(_activeKey);
    } catch (e) {
      throw Exception('Failed to clear active checkpoint: $e');
    }
  }

  /// Close Hive box
  Future<void> close() async {
    try {
      final box = _checkpointBox;
      if (box != null && box.isOpen) {
        await box.close();
      }
      _checkpointBox = null;
    } catch (e) {
      // ignore
    }
  }
}

