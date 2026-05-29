import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/routes/app_routes.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/transaction_tile.dart';

class AccountantDashboardScreen extends ConsumerStatefulWidget {
  const AccountantDashboardScreen({super.key});

  @override
  ConsumerState<AccountantDashboardScreen> createState() =>
      _AccountantDashboardScreenState();
}

class _AccountantDashboardScreenState
    extends ConsumerState<AccountantDashboardScreen> {
  List<Transaction> _queue = [];
  Transaction? _selected;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = _queue.isEmpty;
      _error = null;
    });
    try {
      final items = await ref.read(queueServiceProvider).fetchQueue();
      if (!mounted) return;
      setState(() {
        _queue = items;
        if (_selected != null) {
          final match = items.where((t) => t.id == _selected!.id);
          _selected = match.isNotEmpty ? match.first : null;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _message(Object e) {
    if (e is DioException) {
      return e.response?.data is Map
          ? (e.response!.data['message']?.toString() ?? 'Request failed')
          : 'Network error';
    }
    return e.toString();
  }

  Future<void> _select(Transaction tx) async {
    if (tx.status != 'waiting') {
      setState(() => _selected = tx);
      return;
    }
    setState(() => _loading = true);
    try {
      final updated =
          await ref.read(queueServiceProvider).select(tx.id);
      setState(() => _selected = updated);
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_message(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _complete() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(queueServiceProvider).complete(_selected!.id);
      setState(() => _selected = null);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_message(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authNotifierProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final waiting = _queue.where((t) => t.status == 'waiting').toList();
    final formatter = NumberFormat('#,##0.##');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accountant Queue'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _loading && _queue.isEmpty
          ? const LoadingIndicator(message: 'Loading queue...')
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      if (user != null)
                        ListTile(
                          title: Text(user.name),
                          subtitle: Text('${waiting.length} waiting'),
                        ),
                      if (_error != null)
                        ErrorBanner(message: _error!, onRetry: _refresh),
                      Expanded(
                        child: _queue.isEmpty
                            ? const EmptyState(
                                title: 'Queue is empty',
                                subtitle: 'Waiting customers will appear here.',
                              )
                            : RefreshIndicator(
                                onRefresh: _refresh,
                                child: ListView.builder(
                                  itemCount: _queue.length,
                                  itemBuilder: (_, i) {
                                    final tx = _queue[i];
                                    return TransactionTile(
                                      transaction: tx,
                                      selected: _selected?.id == tx.id,
                                      onTap: () => _select(tx),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 3,
                  child: _selected == null
                      ? const EmptyState(
                          title: 'Select a customer',
                          subtitle: 'Tap a queue item to view details.',
                          icon: Icons.touch_app_outlined,
                        )
                      : _detailPanel(_selected!, formatter),
                ),
              ],
            ),
    );
  }

  Widget _detailPanel(Transaction tx, NumberFormat formatter) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Row(
            children: [
              Text(
                tx.type.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              StatusBadge(status: tx.status),
            ],
          ),
          const SizedBox(height: 8),
          Text('${formatter.format(tx.amount)} ETB',
              style: Theme.of(context).textTheme.headlineSmall),
          const Divider(height: 24),
          _info('Customer', tx.customer?.name ?? tx.accountHolder),
          _info('Account', tx.accountNumber),
          _info('Amount in words', tx.amountWords),
          _info('Deposited by', tx.depositedBy),
          _info('To account', tx.toAccount),
          _info('Date', tx.date),
          const SizedBox(height: 24),
          // Show photo and signature if available
          if (tx.photoUrl != null && tx.photoUrl!.isNotEmpty) ...[
            Text('Photo', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Image.network(tx.photoUrl!, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 16),
          ],
          if (tx.signatureUrl != null && tx.signatureUrl!.isNotEmpty) ...[
            Text('Signature', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Image.network(tx.signatureUrl!, height: 100, fit: BoxFit.contain),
            const SizedBox(height: 16),
          ],
          if (tx.status == 'pending' || tx.status == 'processing')
            ElevatedButton(
              onPressed: _loading ? null : _complete,
              child: const Text('Complete transaction'),
            ),
        ],
      ),
    );
  }

  Widget _info(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
