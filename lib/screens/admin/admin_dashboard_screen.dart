import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/routes/app_routes.dart';
import '../../models/transaction_model.dart';
import '../../models/window_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_title.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/transaction_tile.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _tabIndex = 0;
  bool _loading = false;
  String? _error;

  List<AccountantWithWindow> _accountants = [];
  List<Window> _windows = [];
  List<Window> _liveQueue = [];
  List<Transaction> _transactions = [];
  TransactionTotals _totals = const TransactionTotals();

  String _period = 'daily';
  String _txType = 'all';

  final _accName = TextEditingController();
  final _accEmail = TextEditingController();
  final _accPassword = TextEditingController();
  final _accWindow = TextEditingController();
  final _profileName = TextEditingController();
  final _profilePassword = TextEditingController();
  final _withdrawMin = TextEditingController(text: '100');
  final _withdrawMax = TextEditingController(text: '50000');

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    _profileName.text = user?.name ?? '';
    _loadAll();
  }

  @override
  void dispose() {
    _accName.dispose();
    _accEmail.dispose();
    _accPassword.dispose();
    _accWindow.dispose();
    _profileName.dispose();
    _profilePassword.dispose();
    _withdrawMin.dispose();
    _withdrawMax.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final windowService = ref.read(windowServiceProvider);
      final reportService = ref.read(reportServiceProvider);
      final results = await Future.wait([
        windowService.listAccountants(),
        windowService.listWindows(),
        reportService.fetchLiveQueue(),
        reportService.fetchTransactions(period: _period, type: _txType),
        windowService.fetchSettings(),
      ]);
      if (!mounted) return;
      setState(() {
        _accountants = results[0] as List<AccountantWithWindow>;
        _windows = results[1] as List<Window>;
        _liveQueue = results[2] as List<Window>;
        final report = results[3] as TransactionReport;
        _transactions = report.transactions;
        _totals = report.totals;
        final settings = results[4] as Map<String, double>;
        _withdrawMin.text = settings['withdraw_min']!.toStringAsFixed(0);
        _withdrawMax.text = settings['withdraw_max']!.toStringAsFixed(0);
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

  Future<void> _logout() async {
    await ref.read(authNotifierProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final formatter = NumberFormat('#,##0.##');

    return Scaffold(
      appBar: AppBar(
        title: const BrandTitle(title: 'Admin'),
        actions: [
          IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.about),
            icon: const Icon(Icons.info_outline),
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Column(
        children: [
          if (user != null)
            ListTile(
              leading: CircleAvatar(child: Text(user.name.characters.first)),
              title: Text(user.name),
              subtitle: Text(user.email),
            ),
          if (_error != null)
            ErrorBanner(message: _error!, onRetry: _loadAll),
          Expanded(
            child: _loading && _accountants.isEmpty
                ? const LoadingIndicator()
                : IndexedStack(
                    index: _tabIndex,
                    children: [
                      _overviewTab(formatter),
                      _accountantsTab(),
                      _liveQueueTab(),
                      _transactionsTab(formatter),
                      _settingsTab(),
                      _profileTab(),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Staff'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Queue'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Tx'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _overviewTab(NumberFormat formatter) {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Deposits',
                  value: '${formatter.format(_totals.deposit)} ETB',
                  subtitle: _period,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  label: 'Withdrawals',
                  value: '${formatter.format(_totals.withdraw)} ETB',
                  subtitle: _period,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StatCard(
            label: 'Total volume',
            value: '${formatter.format(_totals.totalVolume)} ETB',
            subtitle: '${_totals.count} transactions',
          ),
          const SizedBox(height: 16),
          Text('Windows (${_windows.length})',
              style: Theme.of(context).textTheme.titleMedium),
          ..._windows.map(
            (w) => ListTile(
              title: Text(w.name),
              subtitle: Text(w.accountant?.name ?? 'Unassigned'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountantsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Add accountant', style: Theme.of(context).textTheme.titleMedium),
        TextField(
            controller: _accName,
            decoration: const InputDecoration(labelText: 'Name')),
        TextField(
            controller: _accEmail,
            decoration: const InputDecoration(labelText: 'Email')),
        TextField(
            controller: _accPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password')),
        TextField(
            controller: _accWindow,
            decoration: const InputDecoration(labelText: 'Window (optional)')),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            try {
              await ref.read(windowServiceProvider).createAccountant(
                    name: _accName.text.trim(),
                    email: _accEmail.text.trim(),
                    password: _accPassword.text,
                    window: _accWindow.text.trim(),
                  );
              _accName.clear();
              _accEmail.clear();
              _accPassword.clear();
              _accWindow.clear();
              await _loadAll();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Accountant created')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_message(e))),
                );
              }
            }
          },
          child: const Text('Create accountant'),
        ),
        const Divider(height: 32),
        ..._accountants.map(
          (a) => Card(
            child: ListTile(
              title: Text(a.name),
              subtitle: Text('${a.email}\n${a.window?.name ?? "No window"}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  await ref
                      .read(windowServiceProvider)
                      .deleteAccountant(a.id);
                  await _loadAll();
                },
              ),
            ),
          ),
        ),
        if (_accountants.isEmpty)
          const EmptyState(title: 'No accountants yet'),
      ],
    );
  }

  Widget _liveQueueTab() {
    if (_liveQueue.isEmpty) {
      return const EmptyState(title: 'Live queue is empty');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _liveQueue.length,
      itemBuilder: (context, index) {
        final window = _liveQueue[index];
        return ExpansionTile(
          title: Text(window.name),
          subtitle: Text(window.accountant?.name ?? 'Unassigned'),
          children: window.transactions
              .map((tx) => TransactionTile(transaction: tx))
              .toList(),
        );
      },
    );
  }

  Widget _transactionsTab(NumberFormat formatter) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _period,
                  decoration: const InputDecoration(labelText: 'Period'),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _period = v);
                    await _loadAll();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _txType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(
                        value: 'deposit', child: Text('Deposit')),
                    DropdownMenuItem(
                        value: 'withdraw', child: Text('Withdraw')),
                    DropdownMenuItem(
                        value: 'transfer', child: Text('Transfer')),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _txType = v);
                    await _loadAll();
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _transactions.isEmpty
              ? const EmptyState(title: 'No transactions')
              : ListView.builder(
                  itemCount: _transactions.length,
                  itemBuilder: (_, i) =>
                      TransactionTile(transaction: _transactions[i]),
                ),
        ),
      ],
    );
  }

  Widget _settingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _withdrawMin,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Withdraw minimum'),
        ),
        TextField(
          controller: _withdrawMax,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Withdraw maximum'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () async {
            try {
              await ref.read(windowServiceProvider).saveSettings(
                    withdrawMin: double.parse(_withdrawMin.text),
                    withdrawMax: double.parse(_withdrawMax.text),
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings saved')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_message(e))),
                );
              }
            }
          },
          child: const Text('Save settings'),
        ),
      ],
    );
  }

  Widget _profileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _profileName,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        TextField(
          controller: _profilePassword,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'New password (optional)',
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () async {
            try {
              final user = await ref.read(authServiceProvider).updateProfile(
                    name: _profileName.text.trim(),
                    password: _profilePassword.text,
                  );
              ref.read(authNotifierProvider.notifier);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Profile updated for ${user.name}')),
                );
              }
              _profilePassword.clear();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_message(e))),
                );
              }
            }
          },
          child: const Text('Update profile'),
        ),
      ],
    );
  }
}
