// File: offline_queue_dao.dart
// DAO untuk queue offline check-in/validation requests

import 'package:hive/hive.dart';

/// Offline Queue DAO — queue check-in requests saat internet offline
/// 
/// Features:
/// - Queue ticket check-in requests
/// - Retry saat online kembali
/// - TTL untuk expired requests (24 jam)
/// - FIFO order (First In First Out)
class OfflineQueueDAO {
  // Nama box Hive untuk queue
  static const String _boxName = 'offline_queue_box';
  
  // Key untuk menyimpan list queue items
  static const String _queueKey = 'queue_items';
  
  // TTL untuk queue item = 24 jam
  // Jika user offline lebih dari 24 jam, queue item dihapus
  static const Duration _queueTtl = Duration(hours: 24);

  // Singleton instance
  static final OfflineQueueDAO _instance = OfflineQueueDAO._internal();
  factory OfflineQueueDAO() => _instance;
  OfflineQueueDAO._internal();

  // Reference ke Hive box
  late Box<dynamic> _queueBox;

  /// Initialize DAO — buka Hive box
  Future<void> initialize() async {
    try {
      // Buka box untuk offline queue
      _queueBox = await Hive.openBox(_boxName);
    } catch (e) {
      throw Exception('Failed to initialize OfflineQueueDAO: $e');
    }
  }

  /// Add request ke queue
  /// 
  /// [endpoint]: API endpoint yang akan di-hit (e.g., /ticket/validate-and-checkin)
  /// [method]: HTTP method (POST, GET, PUT, DELETE)
  /// [data]: Request body/parameters
  /// [timestamp]: Kapan request di-queue (untuk tracking)
  /// 
  /// Setiap item punya struktur:
  /// {
  ///   "id": unique id (timestamp-based),
  ///   "endpoint": endpoint path,
  ///   "method": HTTP method,
  ///   "data": request body,
  ///   "queued_at": ISO timestamp,
  ///   "retry_count": 0 (increment setiap retry)
  /// }
  Future<void> addToQueue({
    required String endpoint,
    required String method,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get existing queue atau create empty list
      List<Map<String, dynamic>> queue = _getQueue();
      
      // Create unique ID berdasarkan timestamp + random suffix
      // Format: "offline_REQ_1696678800_12345"
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final id = 'offline_REQ_$timestamp';
      
      // Create queue item dengan semua metadata
      final queueItem = {
        'id': id, // Unique identifier untuk tracking
        'endpoint': endpoint, // API endpoint path
        'method': method, // HTTP method (POST, GET, etc)
        'data': data, // Request body/parameters
        'queued_at': now.toIso8601String(), // Timestamp kapan di-queue
        'retry_count': 0, // Counter untuk tracking retry attempts
      };
      
      // Add item ke akhir queue (FIFO — First In First Out)
      queue.add(queueItem);
      
      // Save updated queue ke Hive
      await _queueBox.put(_queueKey, queue);
    } catch (e) {
      throw Exception('Failed to add to offline queue: $e');
    }
  }

  /// Get queue items yang belum expired
  /// 
  /// Returns: List<Map> queue items, auto-remove expired items
  /// Queue item dianggap expired jika lebih dari 24 jam di-queue
  List<Map<String, dynamic>> getQueue() {
    try {
      // Get semua queue items dari Hive
      List<Map<String, dynamic>> queue = _getQueue();
      
      // Filter out expired items
      // Item expired jika (now - queued_at) > 24 jam
      final now = DateTime.now();
      queue.removeWhere((item) {
        // Parse queued_at timestamp
        final queuedAt = DateTime.parse(item['queued_at'] as String);
        
        // Hitung umur queue item
        final age = now.difference(queuedAt);
        
        // Jika lebih dari 24 jam, remove dari queue
        return age > _queueTtl;
      });
      
      // Save queue yang sudah di-filter (remove expired items)
      _saveQueue(queue);
      
      return queue;
    } catch (e) {
      print('Error getting queue: $e');
      return [];
    }
  }

  /// Get first item dari queue (untuk di-process/retry)
  /// 
  /// Returns: First Map item dari queue, null jika queue kosong
  /// Digunakan untuk ambil request pertama yang perlu di-retry
  Map<String, dynamic>? getFirstQueueItem() {
    try {
      // Get queue items
      final queue = getQueue(); // Ini akan auto-filter expired
      
      // Return first item atau null jika kosong
      return queue.isNotEmpty ? queue.first : null;
    } catch (e) {
      print('Error getting first queue item: $e');
      return null;
    }
  }

  /// Update retry count untuk queue item
  /// 
  /// [itemId]: ID dari queue item yang mau di-update
  /// [newRetryCount]: New retry count value
  /// 
  /// Digunakan untuk track berapa kali item sudah di-retry
  Future<void> updateRetryCount({
    required String itemId,
    required int newRetryCount,
  }) async {
    try {
      // Get queue items
      List<Map<String, dynamic>> queue = _getQueue();
      
      // Find item dengan matching ID
      final itemIndex = queue.indexWhere((item) => item['id'] == itemId);
      
      // Jika item tidak ditemukan, do nothing
      if (itemIndex == -1) return;
      
      // Update retry count untuk item tersebut
      queue[itemIndex]['retry_count'] = newRetryCount;
      
      // Save updated queue
      await _saveQueue(queue);
    } catch (e) {
      throw Exception('Failed to update retry count: $e');
    }
  }

  /// Remove item dari queue (setelah sukses di-process)
  /// 
  /// [itemId]: ID dari queue item yang mau dihapus
  /// 
  /// Digunakan setelah request berhasil di-retry dan di-kirim ke API
  Future<void> removeFromQueue(String itemId) async {
    try {
      // Get queue items
      List<Map<String, dynamic>> queue = _getQueue();
      
      // Remove item dengan matching ID
      queue.removeWhere((item) => item['id'] == itemId);
      
      // Save updated queue
      await _saveQueue(queue);
    } catch (e) {
      throw Exception('Failed to remove from offline queue: $e');
    }
  }

  /// Clear semua queue items
  /// 
  /// Nuclear option — clear seluruh queue
  Future<void> clear() async {
    try {
      await _queueBox.delete(_queueKey);
    } catch (e) {
      throw Exception('Failed to clear offline queue: $e');
    }
  }

  /// Check apakah queue ada items
  /// 
  /// Returns: true jika ada pending items, false jika kosong
  bool hasQueueItems() {
    final queue = _getQueue();
    return queue.isNotEmpty;
  }

  /// Get queue size (jumlah pending items)
  /// 
  /// Returns: Jumlah items dalam queue
  int getQueueSize() {
    final queue = _getQueue();
    return queue.length;
  }

  /// Close Hive box
  Future<void> close() async {
    try {
      await _queueBox.close();
    } catch (e) {
      print('Error closing offline queue box: $e');
    }
  }

  // ==================== PRIVATE HELPERS ====================

  /// Get queue dari Hive (internal helper)
  /// 
  /// Returns: List<Map> queue items atau empty list jika tidak ada
  List<Map<String, dynamic>> _getQueue() {
    try {
      // Get value dari box
      final data = _queueBox.get(_queueKey);
      
      // Type casting ke List
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      
      // Return empty list jika tidak ada data
      return [];
    } catch (e) {
      print('Error in _getQueue: $e');
      return [];
    }
  }

  /// Save queue ke Hive (internal helper)
  /// 
  /// [queue]: List<Map> queue items
  Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    try {
      // Put updated queue ke box
      await _queueBox.put(_queueKey, queue);
    } catch (e) {
      throw Exception('Failed to save queue: $e');
    }
  }
}

