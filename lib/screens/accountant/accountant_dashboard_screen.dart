import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/routes/app_routes.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_title.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/status_badge.dart';

class AccountantDashboardScreen extends ConsumerStatefulWidget {
  const AccountantDashboardScreen({super.key});

  @override
  ConsumerState<AccountantDashboardScreen> createState() =>
      _AccountantDashboardScreenState();
}

class _AccountantDashboardScreenState
    extends ConsumerState<AccountantDashboardScreen> {
  List<Transaction> _queue = [];
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
      });
      // Precache all photos and signatures in the queue immediately
      _precacheQueueImages(items);
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _precacheQueueImages(List<Transaction> items) {
    for (var tx in items) {
      if (tx.photoUrl != null && tx.photoUrl!.isNotEmpty) {
        precacheImage(NetworkImage(tx.photoUrl!), context);
      }
      if (tx.signatureUrl != null && tx.signatureUrl!.isNotEmpty) {
        precacheImage(NetworkImage(tx.signatureUrl!), context);
      }
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

  Future<void> _logout() async {
    await ref.read(authNotifierProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final waiting = _queue.where((t) => t.status == 'waiting').toList();
    final active = _queue.where((t) => t.status != 'waiting' && t.status != 'completed').toList();
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: BrandTitle(title: loc.queue),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh), tooltip: loc.refresh),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
            tooltip: loc.settingsTitle,
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.about),
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout), tooltip: loc.logout),
        ],
      ),
      body: _loading && _queue.isEmpty
          ? LoadingIndicator(message: loc.splashLoading)
          : RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                slivers: [
                  if (_error != null)
                    SliverToBoxAdapter(
                      child: ErrorBanner(message: _error!, onRetry: _refresh),
                    ),

                  // Summary Stats
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          _statCard(loc.waiting.toUpperCase(), waiting.length.toString(), Colors.blue),
                          const SizedBox(width: 12),
                          _statCard(loc.inProgress.toUpperCase(), active.length.toString(), Colors.orange),
                        ],
                      ),
                    ),
                  ),

                  if (_queue.isEmpty)
                    const SliverFillRemaining(
                      child: EmptyState(
                        title: 'Queue is empty',
                        subtitle: 'No customers are currently waiting.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final tx = _queue[index];
                            return _QueueTile(
                              transaction: tx,
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TransactionDetailScreen(transaction: tx),
                                  ),
                                );
                                if (result == true) {
                                  _refresh();
                                }
                              },
                            );
                          },
                          childCount: _queue.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _QueueTile({required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(transaction.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: transaction.status == 'pending' ? const Color(0xFFD4AF37).withOpacity(0.3) : Colors.transparent),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    "${transaction.queueNumber ?? '#'}",
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.customer?.name ?? transaction.accountHolder ?? 'Unknown Customer',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${transaction.type.toUpperCase()} • ${transaction.amount} ETB',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'pending': return const Color(0xFFD4AF37);
      case 'processing': return Colors.orange;
      case 'waiting': return Colors.blue;
      default: return Colors.grey;
    }
  }
}

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  ConsumerState<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends ConsumerState<TransactionDetailScreen> {
  bool _loading = false;
  late Transaction _tx;

  @override
  void initState() {
    super.initState();
    _tx = widget.transaction;
    if (_tx.status == 'waiting') {
      _select();
    } else {
      _precacheImages();
    }
  }

  void _precacheImages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_tx.photoUrl != null && _tx.photoUrl!.isNotEmpty) {
        precacheImage(NetworkImage(_tx.photoUrl!), context);
      }
      if (_tx.signatureUrl != null && _tx.signatureUrl!.isNotEmpty) {
        precacheImage(NetworkImage(_tx.signatureUrl!), context);
      }
    });
  }

  Future<void> _select() async {
    setState(() => _loading = true);
    try {
      final updated = await ref.read(queueServiceProvider).select(_tx.id);
      if (mounted) {
        setState(() => _tx = updated);
        _precacheImages();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _complete() async {
    setState(() => _loading = true);
    try {
      await ref.read(queueServiceProvider).complete(_tx.id);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadReceipt() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _loading = true);
    try {
      await ref.read(queueServiceProvider).uploadReceipt(_tx.id, File(picked.path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt uploaded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.##');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
      ),
      body: _loading && _tx.status == 'waiting'
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeader(formatter),
                const SizedBox(height: 24),
                _buildDetailSection(),
                const SizedBox(height: 24),
                if (_tx.photoUrl != null) _buildImageSection('Customer Photo', _tx.photoUrl!, fit: BoxFit.cover),
                if (_tx.signatureUrl != null) _buildImageSection('Customer Signature', _tx.signatureUrl!, fit: BoxFit.contain, height: 150),
                const SizedBox(height: 32),
                if (_tx.status != 'completed') ...[
                  ElevatedButton(
                    onPressed: _loading ? null : _complete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('COMPLETE TRANSACTION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _uploadReceipt,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('UPLOAD RECEIPT IMAGE'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ] else ...[
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 64),
                        SizedBox(height: 8),
                        Text('Transaction Completed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildHeader(NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_tx.type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4AF37), letterSpacing: 1.2)),
              StatusBadge(status: _tx.status),
            ],
          ),
          const SizedBox(height: 16),
          Text('${formatter.format(_tx.amount)} ETB', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(_tx.queueNumber != null ? 'QUEUE NUMBER: ${_tx.queueNumber}' : 'NO QUEUE ASSIGNED',
               style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDetailSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _detailRow('Customer', _tx.customer?.name ?? _tx.accountHolder),
          _detailRow('Account', _tx.accountNumber),
          _detailRow('Amount in Words', _tx.amountWords),
          _detailRow('Deposited By', _tx.depositedBy),
          _detailRow('To Account', _tx.toAccount),
          _detailRow('Date', _tx.date, isLast: true),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String? value, {bool isLast = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildImageSection(String title, String url, {BoxFit fit = BoxFit.cover, double height = 200}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            url,
            width: double.infinity,
            height: height,
            fit: fit,
            gaplessPlayback: true, // Prevent flickering during reload
            filterQuality: FilterQuality.medium,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: height,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                    color: const Color(0xFFD4AF37),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              height: height,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}
