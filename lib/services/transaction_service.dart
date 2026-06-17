import 'dart:io';

import 'package:dio/dio.dart';

import '../models/transaction_model.dart';
import 'api_client.dart';

/// Admin transaction listing aligned with Laravel `/transactions/{period}`.
class TransactionService {
  final ApiClient _api;

  TransactionService(this._api);

  Future<TransactionReport> fetchReport({
    required String period,
    String type = 'all',
  }) async {
    final response = await _api.get(
      '/transactions/$period',
      queryParameters: type != 'all' ? {'type': type} : null,
    );
    if (response.data is Map<String, dynamic>) {
      return TransactionReport.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    }
    return const TransactionReport(
      transactions: [],
      totals: TransactionTotals(),
    );
  }

  Future<List<dynamic>> fetchMyTransactions() async {
    final response = await _api.get('/my-transactions');
    return response.data as List;
  }

  Future<List<dynamic>> fetchMyReceipts() async {
    final response = await _api.get('/my-receipts');
    return response.data as List;
  }

  Future<void> createTransaction({
    required Map<String, String> fields,
    required File photo,
    required File signature,
  }) async {
    final formData = FormData.fromMap({
      ...fields,
      'photo': await MultipartFile.fromFile(photo.path, filename: 'photo.jpg'),
      'signature': await MultipartFile.fromFile(signature.path, filename: 'signature.png'),
    });

    await _api.post('/transactions', data: formData);
  }
}
