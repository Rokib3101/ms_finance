import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ms_finance/features/finance/presentation/providers/finance_provider.dart';
import 'package:ms_finance/features/finance/data/models/finance_models.dart';

class TrashManagementScreen extends StatelessWidget {
  const TrashManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('রিসাইকেল বিন / ট্র্যাশ'),
        actions: [
          Consumer<FinanceProvider>(
            builder: (context, provider, _) {
              if (provider.trashedTransactions.isEmpty) {
                return const SizedBox.shrink();
              }
              return TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _showEmptyTrashConfirmation(context, provider),
                icon: const Icon(Icons.delete_sweep, size: 20),
                label: const Text('সব মুছুন'),
              );
            },
          ),
        ],
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, provider, _) {
          final trashed = provider.trashedTransactions;

          if (trashed.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'ট্র্যাশ খালি আছে',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ডিলিট করা ট্রানজেকশনগুলো এখানে জমা হবে।',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: trashed.length,
            itemBuilder: (context, index) {
              final tx = trashed[index];
              final dateStr =
                  DateFormat('dd MMM yyyy, hh:mm a').format(tx.date);
              final deletedAtStr = tx.deletedAt != null
                  ? DateFormat('dd MMM yyyy').format(tx.deletedAt!)
                  : '';
              final isIncome = tx.type == TransactionType.income;
              final isTransfer = tx.type == TransactionType.transfer;

              Color color = Colors.red;
              if (isIncome) color = Colors.green;
              if (isTransfer) color = Colors.blue;

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.1),
                                radius: 18,
                                child: Icon(
                                  isIncome
                                      ? Icons.arrow_downward
                                      : isTransfer
                                          ? Icons.swap_horiz
                                          : Icons.arrow_upward,
                                  color: color,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.category,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            '৳${tx.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      if (tx.note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'নোট: ${tx.note}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                      if (deletedAtStr.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'মুছে ফেলার তারিখ: $deletedAtStr',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade700,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                            ),
                            onPressed: () => _showPermanentDeleteDialog(
                                context, provider, tx),
                            icon: const Icon(Icons.delete_forever, size: 16),
                            label: const Text('স্থায়ীভাবে মুছুন',
                                style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                            ),
                            onPressed: () async {
                              await provider.restoreTransaction(tx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'ট্রানজেকশন সফলভাবে ফিরিয়ে আনা হয়েছে!')),
                                );
                              }
                            },
                            icon: const Icon(Icons.restore, size: 16),
                            label: const Text('রিস্টোর',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPermanentDeleteDialog(
      BuildContext context, FinanceProvider provider, Transaction tx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('স্থায়ীভাবে মুছুন'),
        content: const Text(
            'এই ট্রানজেকশনটি চিরতরে মুছে ফেলা হবে। এটি আর ফিরিয়ে আনা সম্ভব নয়। আপনি কি নিশ্চিত?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await provider.permanentDeleteTransaction(tx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('ট্রানজেকশন স্থায়ীভাবে মুছে ফেলা হয়েছে')),
                );
              }
            },
            child: const Text('স্থায়ী ডিলিট'),
          ),
        ],
      ),
    );
  }

  void _showEmptyTrashConfirmation(
      BuildContext context, FinanceProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ট্র্যাশ খালি করুন'),
        content: const Text(
            'ট্র্যাশে থাকা সমস্ত ট্রানজেকশন স্থায়ীভাবে মুছে ফেলা হবে। আপনি কি নিশ্চিত?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await provider.emptyTrash();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ট্র্যাশ খালি করা হয়েছে')),
                );
              }
            },
            child: const Text('সব ডিলিট করুন'),
          ),
        ],
      ),
    );
  }
}
