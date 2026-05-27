import '../models/transaction_model.dart';
import '../models/window_model.dart';
import 'api_client.dart';
import 'transaction_service.dart';

/// Aggregates admin reporting endpoints (live queue + transaction reports).
class ReportService {
  final ApiClient _api;
  late final TransactionService _transactions;

  ReportService(this._api) : _transactions = TransactionService(_api);

  Future<List<Window>> fetchLiveQueue() async {
    final response = await _api.get('/admin/live-queue');
    final data = response.data;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Window.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<TransactionReport> fetchTransactions({
    required String period,
    String type = 'all',
  }) =>
      _transactions.fetchReport(period: period, type: type);
}
