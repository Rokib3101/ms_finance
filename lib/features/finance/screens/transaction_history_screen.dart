import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ms_finance/features/finance/presentation/providers/finance_provider.dart';
import 'package:ms_finance/features/finance/data/models/finance_models.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  TransactionType? _filterType;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final txs = provider.transactions.where((tx) {
      if (_filterType == null) return true;
      return tx.type == _filterType;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          PopupMenuButton<TransactionType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) => setState(() => _filterType = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All')),
              const PopupMenuItem(
                  value: TransactionType.income, child: Text('Income')),
              const PopupMenuItem(
                  value: TransactionType.expense, child: Text('Expense')),
              const PopupMenuItem(
                  value: TransactionType.transfer, child: Text('Transfer')),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: txs.length,
        itemBuilder: (context, index) {
          final tx = txs[index];
          final wallet = provider.wallets.firstWhere((w) => w.id == tx.walletId,
              orElse: () =>
                  Wallet(id: '', name: 'Unknown', balance: 0, icon: ''));

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getTypeColor(tx.type).withValues(alpha: 0.1),
                child: Icon(_getTypeIcon(tx.type),
                    color: _getTypeColor(tx.type), size: 20),
              ),
              title: Text(tx.category),
              subtitle: Text(
                  '${DateFormat('dd MMM, yyyy').format(tx.date)} • ${wallet.name}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${tx.type == TransactionType.income ? "+" : "-"} ৳${tx.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getTypeColor(tx.type),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () =>
                        _showDeleteConfirmation(context, provider, tx),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, FinanceProvider provider, Transaction tx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
            'Are you sure you want to delete this transaction? Wallet balance will be restored.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              provider.deleteTransaction(tx);
              Navigator.pop(context);
            },
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.arrow_downward;
      case TransactionType.expense:
        return Icons.arrow_upward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }
}
