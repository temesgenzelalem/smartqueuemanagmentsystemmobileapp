import '../models/window_model.dart';
import 'api_client.dart';

class WindowService {
  final ApiClient _api;

  WindowService(this._api);

  Future<List<Window>> listWindows() async {
    final response = await _api.get('/windows');
    final data = response.data;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Window.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Window> createWindow({
    required String name,
    int? accountantId,
  }) async {
    final response = await _api.post(
      '/windows',
      data: {
        'name': name,
        if (accountantId != null) 'accountant_id': accountantId,
      },
    );
    final data = response.data;
    if (data is Map && data['window'] is Map) {
      return Window.fromJson(
        Map<String, dynamic>.from(data['window'] as Map),
      );
    }
    throw WindowException('Failed to create window');
  }

  Future<void> deleteWindow(int id) async {
    await _api.delete('/windows/$id');
  }

  Future<List<AccountantWithWindow>> listAccountants() async {
    final response = await _api.get('/accountants');
    final data = response.data;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => AccountantWithWindow.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<AccountantWithWindow> createAccountant({
    required String name,
    required String email,
    required String password,
    String? window,
  }) async {
    final response = await _api.post(
      '/accountants',
      data: {
        'name': name,
        'email': email,
        'password': password,
        if (window != null && window.isNotEmpty) 'window': window,
      },
    );
    final data = response.data;
    if (data is Map && data['user'] is Map) {
      return AccountantWithWindow.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );
    }
    throw WindowException('Failed to create accountant');
  }

  Future<void> deleteAccountant(int id) async {
    await _api.delete('/accountants/$id');
  }

  Future<Map<String, double>> fetchSettings() async {
    final response = await _api.get('/admin/settings');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return {
        'withdraw_min': (data['withdraw_min'] as num?)?.toDouble() ?? 100,
        'withdraw_max': (data['withdraw_max'] as num?)?.toDouble() ?? 50000,
      };
    }
    return {'withdraw_min': 100, 'withdraw_max': 50000};
  }

  Future<void> saveSettings({
    required double withdrawMin,
    required double withdrawMax,
  }) async {
    await _api.post(
      '/admin/settings',
      data: {
        'withdraw_min': withdrawMin,
        'withdraw_max': withdrawMax,
      },
    );
  }
}

class WindowException implements Exception {
  final String message;
  WindowException(this.message);

  @override
  String toString() => message;
}
