import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ms_finance/features/finance/presentation/providers/finance_provider.dart';

class MonthlySummaryScreen extends StatelessWidget {
  const MonthlySummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final now = DateTime.now();
    final summaries = provider.getYearlyMonthlySummaries(now.year);
    final monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Summary')),
      body: summaries.isEmpty
          ? const Center(child: Text('No data found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: summaries.length,
              itemBuilder: (context, index) {
                final month = summaries.keys.elementAt(index);
                final data = summaries[month]!;
                final isProfit = data['balance']! >= 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${monthNames[month]} ${now.year}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isProfit ? Colors.green : Colors.red)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isProfit ? 'Profit' : 'Loss',
                                style: TextStyle(
                                    color: isProfit ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        _buildRow(
                            'Total Income', data['income']!, Colors.green),
                        const SizedBox(height: 8),
                        _buildRow(
                            'Total Expense', data['expense']!, Colors.red),
                        const Divider(height: 32),
                        _buildRow(
                          isProfit ? 'Net Balance' : 'Net Deficit',
                          data['balance']!.abs(),
                          isProfit ? Colors.blue : Colors.red,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRow(String label, double amount, Color color,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700])),
        Text(
          '৳ ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 16,
          ),
        ),
      ],
    );
  }
}
