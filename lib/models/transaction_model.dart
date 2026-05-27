import 'user_model.dart';

class Transaction {
  final int id;
  final int userId;
  final int? windowId;
  final String status;
  final String type;
  final double amount;
  final String? accountNumber;
  final String? accountHolder;
  final String? amountWords;
  final String? depositedBy;
  final String? toAccount;
  final String? photo;
  final String? signature;
  final String? photoUrl;
  final String? signatureUrl;
  final String? date;
  final int? priority;
  final int? queueNumber;
  final String? createdAt;
  final User? customer;

  const Transaction({
    required this.id,
    required this.userId,
    this.windowId,
    required this.status,
    required this.type,
    required this.amount,
    this.accountNumber,
    this.accountHolder,
    this.amountWords,
    this.depositedBy,
    this.toAccount,
    this.photo,
    this.signature,
    this.photoUrl,
    this.signatureUrl,
    this.date,
    this.priority,
    this.queueNumber,
    this.createdAt,
    this.customer,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    User? customer;
    final userJson = json['user'];
    if (userJson is Map<String, dynamic>) {
      customer = User.fromJson(userJson);
    }

    return Transaction(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      windowId: json['window_id'] == null ? null : _asInt(json['window_id']),
      status: json['status']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      amount: _asDouble(json['amount']),
      accountNumber: json['account_number']?.toString(),
      accountHolder: json['account_holder']?.toString(),
      amountWords: json['amount_words']?.toString(),
      depositedBy: json['deposited_by']?.toString(),
      toAccount: json['to_account']?.toString(),
      photo: json['photo']?.toString(),
      signature: json['signature']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      signatureUrl: json['signature_url']?.toString(),
      date: json['date']?.toString(),
      priority: json['priority'] == null ? null : _asInt(json['priority']),
      queueNumber:
          json['queue_number'] == null ? null : _asInt(json['queue_number']),
      createdAt: json['created_at']?.toString(),
      customer: customer,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'window_id': windowId,
        'status': status,
        'type': type,
        'amount': amount,
        'account_number': accountNumber,
        'account_holder': accountHolder,
        'amount_words': amountWords,
        'deposited_by': depositedBy,
        'to_account': toAccount,
        'photo': photo,
        'signature': signature,
        'photo_url': photoUrl,
        'signature_url': signatureUrl,
        'date': date,
        'priority': priority,
        'queue_number': queueNumber,
        'created_at': createdAt,
        if (customer != null) 'user': customer!.toJson(),
      };

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}

class TransactionTotals {
  final double deposit;
  final double withdraw;
  final double transfer;
  final int count;

  const TransactionTotals({
    this.deposit = 0,
    this.withdraw = 0,
    this.transfer = 0,
    this.count = 0,
  });

  factory TransactionTotals.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TransactionTotals();
    return TransactionTotals(
      deposit: Transaction._asDouble(json['deposit']),
      withdraw: Transaction._asDouble(json['withdraw']),
      transfer: Transaction._asDouble(json['transfer']),
      count: Transaction._asInt(json['count']),
    );
  }

  double get totalVolume => deposit + withdraw + transfer;
}

class TransactionReport {
  final List<Transaction> transactions;
  final TransactionTotals totals;

  const TransactionReport({
    required this.transactions,
    required this.totals,
  });

  factory TransactionReport.fromJson(Map<String, dynamic> json) {
    final list = json['transactions'];
    final items = list is List
        ? list
            .whereType<Map>()
            .map((e) => Transaction.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <Transaction>[];
    return TransactionReport(
      transactions: items,
      totals: TransactionTotals.fromJson(
        json['totals'] is Map<String, dynamic>
            ? json['totals'] as Map<String, dynamic>
            : null,
      ),
    );
  }
}
