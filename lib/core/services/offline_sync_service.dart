import '../constants/app_constants.dart';
import 'hive_service.dart';

/// Placeholder for future offline queue sync (writes pending ops to Hive).
class OfflineSyncService {
  Future<List<Map<String, dynamic>>> pendingOperations() async {
    final raw = HiveService.get<List<dynamic>>(AppConstants.hiveKeyPendingSync);
    if (raw == null) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> enqueue({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final pending = await pendingOperations();
    pending.add({
      'method': method,
      'path': path,
      'body': body,
      'created_at': DateTime.now().toIso8601String(),
    });
    await HiveService.put(AppConstants.hiveKeyPendingSync, pending);
  }

  /// Placeholder: flush pending operations when connectivity returns.
  Future<void> syncPending() async {
    // Intentionally no-op until backend supports batch replay.
  }
}
