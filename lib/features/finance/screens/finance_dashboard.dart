import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:ms_finance/features/finance/presentation/providers/finance_provider.dart';
import 'package:ms_finance/features/finance/data/models/finance_models.dart';
import 'package:ms_finance/core/navigation/app_router.dart';

class FinanceDashboard extends StatelessWidget {
  const FinanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final now = DateTime.now();
    final monthlyIncome =
        provider.getMonthlyTotal(TransactionType.income, now.month, now.year);
    final monthlyExpense =
        provider.getMonthlyTotal(TransactionType.expense, now.month, now.year);
    final currentMonthCategoryData = provider.getCategoryData(
      TransactionType.expense,
      month: now.month,
      year: now.year,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Personal Finance'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Smart Insights',
            icon: const Icon(Icons.insights),
            onPressed: () => context.push(AppRoutes.financeInsights),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push(AppRoutes.financeHistory),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.financeSettings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthlySummary(context, monthlyIncome, monthlyExpense),
            const SizedBox(height: 24),
            _buildSectionHeader('My Wallets', Icons.account_balance_wallet),
            const SizedBox(height: 12),
            _buildWalletGrid(context, provider.wallets),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            if (currentMonthCategoryData.isNotEmpty) ...[
              _buildSectionHeader('Expense Analysis', Icons.pie_chart),
              const SizedBox(height: 12),
              _buildExpenseChart(context, provider),
              const SizedBox(height: 24),
            ],
            _buildSectionHeader('Recent Transactions', Icons.receipt_long),
            const SizedBox(height: 12),
            _buildRecentTransactions(context, provider),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.financeTransactionEntry),
        label: const Text('New Entry'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMonthlySummary(
      BuildContext context, double income, double expense) {
    final balance = income - expense;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3C72).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Net Savings (This Month)',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            '৳${balance.toStringAsFixed(0)}',
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _summaryCard('Monthly Income', income,
                    Icons.arrow_downward, Colors.greenAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard('Monthly Expense', expense,
                    Icons.arrow_upward, Colors.redAccent),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _summaryCard(
      String title, double amount, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: iconColor.withValues(alpha: 0.2),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
                Text(
                  '৳${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1E3C72)),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildWalletGrid(BuildContext context, List<Wallet> wallets) {
    if (wallets.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No wallets found. Add a wallet from Finance Settings.'),
        ),
      );
    }
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: wallets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final wallet = wallets[index];
          return Container(
            width: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        size: 18, color: Color(0xFF1E3C72)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(wallet.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('৳${wallet.balance.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(context, 'Assets', Icons.account_balance,
              Colors.blue, AppRoutes.financeAssets),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(context, 'Profit/Loss', Icons.trending_up,
              Colors.teal, AppRoutes.financeMonthlySummary),
        ),
      ],
    );
  }

  Widget _actionButton(BuildContext context, String title, IconData icon,
      Color color, String route) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(title,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseChart(BuildContext context, FinanceProvider provider) {
    final now = DateTime.now();
    final categoryData = provider.getCategoryData(
      TransactionType.expense,
      month: now.month,
      year: now.year,
    );
    final totalExpense = provider.getMonthlyTotal(
      TransactionType.expense,
      now.month,
      now.year,
    );

    if (categoryData.isEmpty || totalExpense == 0) {
      return const SizedBox();
    }

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(categoryData.length, (i) {
                  final entry = categoryData.entries.elementAt(i);
                  final pct = (entry.value / totalExpense) * 100;
                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: entry.value,
                    title: '${pct.toStringAsFixed(0)}%',
                    radius: 35,
                    titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: List.generate(categoryData.length, (i) {
              final entry = categoryData.entries.elementAt(i);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 8, height: 8, color: colors[i % colors.length]),
                  const SizedBox(width: 4),
                  Text(entry.key, style: const TextStyle(fontSize: 11)),
                ],
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(
      BuildContext context, FinanceProvider provider) {
    final now = DateTime.now();
    final currentMonthTxs =
        provider.getTransactionsForMonth(now.month, now.year);
    final txs = currentMonthTxs.take(5).toList();

    if (txs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No transactions recorded this month.'),
        ),
      );
    }

    return Column(
      children: txs
          .map((tx) => Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        _getTypeColor(tx.type).withValues(alpha: 0.1),
                    child: Icon(_getTypeIcon(tx.type),
                        color: _getTypeColor(tx.type), size: 20),
                  ),
                  title: Text(tx.category,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(DateFormat('dd MMM  hh:mm a').format(tx.date),
                      style: const TextStyle(fontSize: 11)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${tx.type == TransactionType.income ? "+" : "-"} ৳${tx.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getTypeColor(tx.type),
                            fontSize: 15),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent, size: 20),
                        onPressed: () =>
                            _showDeleteConfirmation(context, provider, tx),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
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
    return type == TransactionType.income ? Colors.green : Colors.red;
  }

  IconData _getTypeIcon(TransactionType type) {
    return type == TransactionType.income
        ? Icons.arrow_downward
        : Icons.arrow_upward;
  }
}
