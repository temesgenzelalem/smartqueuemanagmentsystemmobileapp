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
}
