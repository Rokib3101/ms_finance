import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ms_finance/features/finance/presentation/providers/finance_provider.dart';
import 'package:ms_finance/features/finance/data/models/finance_models.dart';

class SmartInsightsScreen extends StatefulWidget {
  const SmartInsightsScreen({super.key});

  @override
  State<SmartInsightsScreen> createState() => _SmartInsightsScreenState();
}

class _SmartInsightsScreenState extends State<SmartInsightsScreen> {
  int? _selectedMonth;
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    final financeProvider = Provider.of<FinanceProvider>(context);
    final now = DateTime.now();

    _selectedMonth ??= now.month;
    _selectedYear ??= now.year;

    final monthlyHealthList = financeProvider.getAllMonthlyFinancialHealth();

    final monthlyIncome = financeProvider.getMonthlyTotal(
      TransactionType.income,
      _selectedMonth!,
      _selectedYear!,
    );
    final monthlyExpense = financeProvider.getMonthlyTotal(
      TransactionType.expense,
      _selectedMonth!,
      _selectedYear!,
    );
    final savings = monthlyIncome - monthlyExpense;
    final savingsRate =
        monthlyIncome > 0 ? (savings / monthlyIncome) * 100 : 0.0;
    final isCurrentMonth =
        (_selectedMonth == now.month && _selectedYear == now.year);

    final selectedDate = DateTime(_selectedYear!, _selectedMonth!);
    final selectedMonthName = DateFormat('MMMM yyyy').format(selectedDate);

    final categoryData = financeProvider.getCategoryData(
      TransactionType.expense,
      month: _selectedMonth!,
      year: _selectedYear!,
    );

    var sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Insights'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthSelectorHeader(
              context,
              monthName: selectedMonthName,
              isCurrentMonth: isCurrentMonth,
              monthlyHealthList: monthlyHealthList,
            ),
            const SizedBox(height: 16),
            _buildMonthHealthCard(
              monthName: selectedMonthName,
              isCurrentMonth: isCurrentMonth,
              income: monthlyIncome,
              expense: monthlyExpense,
              savings: savings,
              savingsRate: savingsRate,
              color: isCurrentMonth ? Colors.blue[800]! : Colors.blueGrey[800]!,
            ),
            const SizedBox(height: 24),
            Text(
              'Category-wise Expense Analysis ($selectedMonthName)',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (sortedCategories.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No expense data found for this month.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedCategories.length,
                itemBuilder: (context, index) {
                  final entry = sortedCategories[index];
                  final percentage = monthlyExpense > 0
                      ? (entry.value / monthlyExpense) * 100
                      : 0.0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(entry.key,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        color: Colors.redAccent,
                      ),
                      trailing: Text(
                        '৳${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelectorHeader(
    BuildContext context, {
    required String monthName,
    required bool isCurrentMonth,
    required List<Map<String, dynamic>> monthlyHealthList,
  }) {
    return InkWell(
      onTap: () => _showMonthSelectionSheet(context, monthlyHealthList),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.calendar_month,
                      color: Theme.of(context).primaryColor),
                  const SizedBox(width: 10),
                  Text(
                    monthName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (isCurrentMonth) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'বর্তমান মাস',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Theme.of(context).primaryColor,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthSelectionSheet(
    BuildContext context,
    List<Map<String, dynamic>> monthlyHealthList,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'মাস নির্বাচন করুন (Select Month)',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: monthlyHealthList.length,
                    itemBuilder: (context, index) {
                      final item = monthlyHealthList[index];
                      final year = item['year'] as int;
                      final month = item['month'] as int;
                      final isCurrent = item['isCurrentMonth'] as bool;
                      final isSelected =
                          (_selectedMonth == month && _selectedYear == year);

                      final name =
                          DateFormat('MMMM yyyy').format(DateTime(year, month));

                      return ListTile(
                        leading: Icon(
                          Icons.calendar_today,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                        title: Row(
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.black87,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'বর্তমান মাস',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: Theme.of(context).primaryColor)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedMonth = month;
                            _selectedYear = year;
                          });
                          Navigator.pop(bottomSheetContext);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthHealthCard({
    required String monthName,
    required bool isCurrentMonth,
    required double income,
    required double expense,
    required double savings,
    required double savingsRate,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Monthly Financial Health ($monthName)',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (isCurrentMonth)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.greenAccent, width: 1),
                  ),
                  child: const Text(
                    'বর্তমান মাস',
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _rowItem('Total Income:', '৳${income.toStringAsFixed(0)}',
              Colors.greenAccent),
          _rowItem('Total Expense:', '৳${expense.toStringAsFixed(0)}',
              Colors.redAccent),
          const Divider(color: Colors.white24),
          _rowItem('Savings:', '৳${savings.toStringAsFixed(0)}',
              savings >= 0 ? Colors.greenAccent : Colors.orangeAccent),
          _rowItem('Savings Rate:', '${savingsRate.toStringAsFixed(1)}%',
              Colors.white),
        ],
      ),
    );
  }

  Widget _rowItem(String label, String value, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 15)),
          Text(value,
              style: TextStyle(
                  color: valColor, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
