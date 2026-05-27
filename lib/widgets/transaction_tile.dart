import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import 'status_badge.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final bool selected;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.##');
    return Card(
      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        onTap: onTap,
        title: Text(
          '${transaction.type.toUpperCase()} — ${formatter.format(transaction.amount)} ETB',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          transaction.customer?.name ??
              transaction.accountHolder ??
              'Customer #${transaction.userId}',
        ),
        trailing: StatusBadge(status: transaction.status),
      ),
    );
  }
}
