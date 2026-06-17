import 'dart:io';

import 'package:dio/dio.dart';

import '../core/constants/app_constants.dart';
import '../core/services/hive_service.dart';
import '../models/transaction_model.dart';
import 'api_client.dart';

class QueueService {
  final ApiClient _api;

  QueueService(this._api);

  Future<List<Transaction>> fetchQueue() async {
    try {
      final response = await _api.get('/queue');
      final list = _parseList(response.data);
      await HiveService.put(
        AppConstants.hiveKeyQueue,
        list.map((e) => e.toJson()).toList(),
      );
      return list;
    } catch (e) {
      final cached = HiveService.get<List<dynamic>>(AppConstants.hiveKeyQueue);
      if (cached != null) {
        return cached
            .whereType<Map>()
            .map((m) => Transaction.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
      rethrow;
    }
  }

  Future<Transaction?> fetchCurrent() async {
    final response = await _api.get('/queue/current');
    final data = response.data;
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      return Transaction.fromJson(data);
    }
    return null;
  }

  Future<Transaction> callNext() async {
    final response = await _api.post('/queue/call-next');
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return Transaction.fromJson(
        Map<String, dynamic>.from(data['data'] as Map),
      );
    }
    throw QueueException('No customers in queue');
  }

  Future<Transaction> select(int id) async {
    final response = await _api.post('/queue/select/$id');
    return Transaction.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> process(int id) async {
    await _api.post('/queue/process/$id');
  }

  Future<void> complete(int id) async {
    await _api.post('/queue/complete/$id');
  }

  Future<void> uploadReceipt(int transactionId, File file) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(file.path, filename: 'receipt.jpg'),
    });
    await _api.post('/receipts/$transactionId', data: formData);
  }

  List<Transaction> _parseList(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Transaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class QueueException implements Exception {
  final String message;
  QueueException(this.message);

  @override
  String toString() => message;
}
