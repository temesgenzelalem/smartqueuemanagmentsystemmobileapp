import 'transaction_model.dart';
import 'user_model.dart';

class Window {
  final int id;
  final String name;
  final int? accountantId;
  final User? accountant;
  final List<Transaction> transactions;

  const Window({
    required this.id,
    required this.name,
    this.accountantId,
    this.accountant,
    this.transactions = const [],
  });

  factory Window.fromJson(Map<String, dynamic> json) {
    User? accountant;
    final accountantJson = json['accountant'];
    if (accountantJson is Map<String, dynamic>) {
      accountant = User.fromJson(accountantJson);
    }

    final txList = json['transactions'];
    final transactions = txList is List
        ? txList
            .whereType<Map>()
            .map((e) => Transaction.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <Transaction>[];

    return Window(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      accountantId: json['accountant_id'] == null
          ? null
          : (json['accountant_id'] is int
              ? json['accountant_id'] as int
              : int.tryParse('${json['accountant_id']}')),
      accountant: accountant,
      transactions: transactions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'accountant_id': accountantId,
        if (accountant != null) 'accountant': accountant!.toJson(),
        'transactions': transactions.map((e) => e.toJson()).toList(),
      };
}

class AccountantWithWindow extends User {
  final Window? window;

  const AccountantWithWindow({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    this.window,
  });

  factory AccountantWithWindow.fromJson(Map<String, dynamic> json) {
    Window? window;
    final windowJson = json['window'];
    if (windowJson is Map<String, dynamic>) {
      window = Window.fromJson(windowJson);
    }
    return AccountantWithWindow(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'accountant',
      window: window,
    );
  }
}
