import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_state.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/queue_service.dart';
import '../services/report_service.dart';
import '../services/transaction_service.dart';
import '../services/window_service.dart';
import 'auth_notifier.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(apiClient: ref.watch(apiClientProvider));
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

final queueServiceProvider = Provider<QueueService>((ref) {
  return QueueService(ref.watch(apiClientProvider));
});

final windowServiceProvider = Provider<WindowService>((ref) {
  return WindowService(ref.watch(apiClientProvider));
});

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(ref.watch(apiClientProvider));
});

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService(ref.watch(apiClientProvider));
});
