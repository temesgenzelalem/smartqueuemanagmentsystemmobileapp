import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_title.dart';
import '../../services/pdf_service.dart';
import '../../services/transaction_service.dart';

class CustomerDashboardScreen extends ConsumerStatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  ConsumerState<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends ConsumerState<CustomerDashboardScreen> {
  int _currentIndex = 0;
  final Set<int> _notifiedTxs = {};

  Future<void> _ringThreeTimes() async {
    try {
      debugPrint("ALARM: Starting high-volume ring sequence...");
      for (int i = 0; i < 3; i++) {
        debugPrint("ALARM: Beep $i...");
        await FlutterRingtonePlayer().play(
          android: AndroidSounds.notification,
          ios: IosSounds.glass,
          looping: false,
          volume: 1.0,
          asAlarm: true,
        );
        await Future.delayed(const Duration(milliseconds: 1800));
      }
    } catch (e) {
      debugPrint("Ringtone error: $e");
    }
  }

  void _showCalledAlert(String queueNumber) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text("🔔 YOU ARE CALLED! Queue: $queueNumber")),
          ],
        ),
        backgroundColor: const Color(0xFFD4AF37),
        duration: const Duration(seconds: 15),
        behavior: SnackBarBehavior.floating,
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.campaign, color: Color(0xFFD4AF37), size: 32),
            SizedBox(width: 10),
            Text("Attention!"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("It is your turn at the window.", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4AF37)),
              ),
              child: Text(
                "QUEUE #$queueNumber",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("I AM COMING", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _checkAndNotify(List<dynamic> txs) {
    for (var tx in txs) {
      final dynamic rawId = tx['id'];
      final int id = rawId is int ? rawId : (int.tryParse(rawId.toString()) ?? 0);
      final status = (tx['status'] as String? ?? '').toLowerCase();

      if ((status == 'pending' || status == 'called' || status == 'processing') && !_notifiedTxs.contains(id)) {
        _notifiedTxs.add(id);
        _ringThreeTimes();
        _showCalledAlert(tx['queue_number']?.toString() ?? "#");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: BrandTitle(title: loc.dashboard),
        actions: [
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
          IconButton(
            tooltip: "Test Sound",
            icon: const Icon(Icons.volume_up),
            onPressed: _ringThreeTimes,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              }
            },
            tooltip: loc.logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          MyTransactionsView(onDataFetched: _checkAndNotify),
          const NewTransactionView(),
          const MyReceiptsView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.list_alt), label: loc.queue),
          BottomNavigationBarItem(icon: const Icon(Icons.add_circle_outline), label: loc.newRequest),
          BottomNavigationBarItem(icon: const Icon(Icons.receipt_long), label: loc.receipts),
        ],
      ),
    );
  }
}

class MyTransactionsView extends ConsumerStatefulWidget {
  final Function(List<dynamic>) onDataFetched;
  const MyTransactionsView({super.key, required this.onDataFetched});

  @override
  ConsumerState<MyTransactionsView> createState() => _MyTransactionsViewState();
}

class _MyTransactionsViewState extends ConsumerState<MyTransactionsView> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchTransactions(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTransactions({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final txs = await ref.read(transactionServiceProvider).fetchMyTransactions();
      if (mounted) {
        widget.onDataFetched(txs);
        setState(() {
          _transactions = txs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_transactions.isEmpty) {
      return Center(child: Text('${loc.queue} is empty'));
    }

    final calledTx = _transactions.cast<Map<String, dynamic>>().firstWhere(
          (tx) => tx['status'] == 'pending',
          orElse: () => {},
        );

    return Column(
      children: [
        if (calledTx.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.amber.shade700,
            child: Text(
              '🔔 You are called! Queue: ${calledTx['queue_number']} — Proceed to window.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchTransactions,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final tx = _transactions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text('${tx['type']}'.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Amount: ${tx['amount']} ETB\nAccount: ${tx['account_number'] ?? "N/A"}'),
                    trailing: _StatusChip(status: tx['status']),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class NewTransactionView extends ConsumerStatefulWidget {
  const NewTransactionView({super.key});

  @override
  ConsumerState<NewTransactionView> createState() => _NewTransactionViewState();
}

class _NewTransactionViewState extends ConsumerState<NewTransactionView> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumber = TextEditingController();
  final _accountHolder = TextEditingController();
  final _amount = TextEditingController();
  final _amountWords = TextEditingController();
  final _depositedBy = TextEditingController();
  final _toAccount = TextEditingController();

  String _type = 'deposit';
  String? _windowId;
  List<dynamic> _windows = [];
  File? _photo;
  bool _isLoading = false;

  final _sigController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    _fetchWindows();
  }

  @override
  void dispose() {
    _accountNumber.dispose();
    _accountHolder.dispose();
    _amount.dispose();
    _amountWords.dispose();
    _depositedBy.dispose();
    _toAccount.dispose();
    _sigController.dispose();
    super.dispose();
  }

  Future<void> _fetchWindows() async {
    try {
      final response = await ref.read(apiClientProvider).get('/available-windows');
      if (mounted) setState(() => _windows = response.data as List);
    } catch (_) {}
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_windowId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a window')));
      return;
    }
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a photo')));
      return;
    }
    if (_sigController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide your signature')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final sigBytes = await _sigController.toPngBytes();
      final tempDir = await getTemporaryDirectory();
      final sigFile = File('${tempDir.path}/signature.png');
      await sigFile.writeAsBytes(sigBytes!);

      // Clean the account number (remove any spaces or non-digits)
      final cleanAccountNumber = _accountNumber.text.replaceAll(RegExp(r'\s+'), '');

      final fields = {
        'type': _type,
        'window_id': _windowId!,
        'account_number': cleanAccountNumber,
        'account_holder': _accountHolder.text.trim(),
        'amount': _amount.text.trim(),
        'amount_words': _amountWords.text.trim(),
        'deposited_by': _depositedBy.text.trim().isEmpty ? _accountHolder.text.trim() : _depositedBy.text.trim(),
        'to_account': _toAccount.text.trim(),
        'date': DateTime.now().toIso8601String().split('T').first,
      };

      await ref.read(transactionServiceProvider).createTransaction(
            fields: fields,
            photo: _photo!,
            signature: sigFile,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction submitted successfully!')));
        _formKey.currentState!.reset();
        setState(() {
          _photo = null;
          _sigController.clear();
          _windowId = null;
        });
        // Refresh the queue list
        _fetchWindows();
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException) {
        errorMessage = e.response?.data['message'] ?? e.message;
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission Error: $errorMessage')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Step 1: Choose Service', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'deposit', label: Text('Deposit')),
                ButtonSegment(value: 'withdraw', label: Text('Withdraw')),
                ButtonSegment(value: 'transfer', label: Text('Transfer')),
              ],
              selected: {_type},
              onSelectionChanged: (val) => setState(() => _type = val.first),
            ),
            const SizedBox(height: 16),
            const Text('Select Window', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _windowId,
              items: _windows.map((w) {
                final count = w['waiting_count'] ?? 0;
                return DropdownMenuItem(
                  value: '${w['id']}',
                  child: Text('${w['name']} ($count ${loc.customersWaiting})')
                );
              }).toList(),
              onChanged: (val) => setState(() => _windowId = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            const Text('Step 2: Transaction Details', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(controller: _accountNumber, decoration: InputDecoration(labelText: loc.accountNumber), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextFormField(controller: _accountHolder, decoration: InputDecoration(labelText: loc.accountHolder)),
            const SizedBox(height: 12),
            TextFormField(controller: _amount, decoration: InputDecoration(labelText: loc.amount), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextFormField(controller: _amountWords, decoration: const InputDecoration(labelText: 'Amount in Words')),
            if (_type == 'transfer') ...[
              const SizedBox(height: 12),
              TextFormField(controller: _toAccount, decoration: const InputDecoration(labelText: 'Recipient Account')),
            ],
            const SizedBox(height: 24),
            const Text('Step 3: Upload Photo', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_photo != null) Image.file(_photo!, height: 150, fit: BoxFit.cover),
            ElevatedButton.icon(onPressed: _pickPhoto, icon: const Icon(Icons.camera_alt), label: const Text('Pick Image')),
            const SizedBox(height: 24),
            const Text('Step 4: Signature', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
              child: Signature(controller: _sigController, height: 150, backgroundColor: Colors.white),
            ),
            TextButton(onPressed: () => _sigController.clear(), child: const Text('Clear Signature')),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading ? const CircularProgressIndicator() : Text(loc.submit),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class MyReceiptsView extends ConsumerStatefulWidget {
  const MyReceiptsView({super.key});

  @override
  ConsumerState<MyReceiptsView> createState() => _MyReceiptsViewState();
}

class _MyReceiptsViewState extends ConsumerState<MyReceiptsView> {
  List<dynamic> _receipts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReceipts();
  }

  Future<void> _fetchReceipts() async {
    setState(() => _isLoading = true);
    try {
      final data = await ref.read(transactionServiceProvider).fetchMyReceipts();
      if (mounted) setState(() => _receipts = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_receipts.isEmpty) return const Center(child: Text('No receipts yet.'));

    return RefreshIndicator(
      onRefresh: _fetchReceipts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _receipts.length,
        itemBuilder: (context, index) {
          final r = _receipts[index];
          final tx = r['transaction'];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text('${tx['type']}'.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Amount: ${tx['amount']} ETB\nDate: ${r['created_at']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    onPressed: () => PdfService.printReceipt(tx, r['receipt_url']),
                    tooltip: 'Print to PDF',
                  ),
                ),
                if (r['receipt_url'] != null)
                  Image.network(r['receipt_url'], width: double.infinity, height: 200, fit: BoxFit.cover),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (status == 'completed') color = Colors.green;
    if (status == 'pending' || status == 'processing') color = Colors.orange;

    return Chip(
      label: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
      backgroundColor: color,
    );
  }
}
