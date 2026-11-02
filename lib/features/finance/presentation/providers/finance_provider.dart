import 'package:flutter/material.dart';
import '../../data/models/finance_models.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../data/repositories/hive_finance_repository.dart';

class FinanceProvider extends ChangeNotifier {
  final FinanceRepository _repository;

  FinanceProvider({FinanceRepository? repository})
      : _repository = repository ?? HiveFinanceRepository();

  List<Transaction> get transactions => _repository.getTransactions();
  List<Transaction> get trashedTransactions =>
      _repository.getTrashedTransactions();
  List<Wallet> get wallets => _repository.getWallets();
  List<Category> get categories => _repository.getCategories();

  double get totalBalance => wallets.fold(0, (sum, w) => sum + w.balance);

  // Category Management
  Future<void> addCategory(Category category) async {
    await _repository.addCategory(category);
    notifyListeners();
  }

  Future<void> deleteCategory(String categoryId) async {
    await _repository.deleteCategory(categoryId);
    notifyListeners();
  }

  List<Category> getCategoriesByType(TransactionType type) {
    return categories.where((c) => c.type == type).toList();
  }

  // Wallet Management
  Future<void> addWallet(Wallet wallet) async {
    await _repository.addWallet(wallet);
    notifyListeners();
  }

  Future<void> updateWallet(Wallet wallet) async {
    await _repository.updateWallet(wallet);
    notifyListeners();
  }

  Future<void> deleteWallet(String walletId) async {
    await _repository.deleteWallet(walletId);
    notifyListeners();
  }

  // Transaction Management
  Future<void> addTransaction(Transaction tx) async {
    await _repository.addTransaction(tx);
    notifyListeners();
  }

  // Soft Delete (Move to Trash)
  Future<void> deleteTransaction(Transaction tx) async {
    await _repository.deleteTransaction(tx);
    notifyListeners();
  }

  // Restore from Trash
  Future<void> restoreTransaction(Transaction tx) async {
    await _repository.restoreTransaction(tx);
    notifyListeners();
  }

  // Permanent Delete
  Future<void> permanentDeleteTransaction(Transaction tx) async {
    await _repository.permanentDeleteTransaction(tx);
    notifyListeners();
  }

  // Empty Trash
  Future<void> emptyTrash() async {
    await _repository.emptyTrash();
    notifyListeners();
  }

  Future<void> clearAllTransactions() async {
    await _repository.clearAllTransactions();
    notifyListeners();
  }

  Future<void> clearSelectiveData({
    int? month,
    int? year,
    bool clearIncome = false,
    bool clearExpense = false,
    bool clearWallets = false,
  }) async {
    await _repository.clearSelectiveData(
      month: month,
      year: year,
      clearIncome: clearIncome,
      clearExpense: clearExpense,
      clearWallets: clearWallets,
    );
    notifyListeners();
  }

  void reloadData() {
    notifyListeners();
  }

  // Analytics
  double getMonthlyTotal(TransactionType type, int month, int year) {
    return transactions
        .where((tx) =>
            tx.type == type && tx.date.month == month && tx.date.year == year)
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  List<Transaction> getTransactionsForMonth(int month, int year) {
    return transactions
        .where((tx) => tx.date.month == month && tx.date.year == year)
        .toList();
  }

  Map<int, Map<String, double>> getYearlyMonthlySummaries(int year) {
    final summaries = <int, Map<String, double>>{};
    for (int m = 1; m <= 12; m++) {
      double income = getMonthlyTotal(TransactionType.income, m, year);
      double expense = getMonthlyTotal(TransactionType.expense, m, year);
      if (income > 0 || expense > 0) {
        summaries[m] = {
          'income': income,
          'expense': expense,
          'balance': income - expense,
        };
      }
    }
    return summaries;
  }

  Map<String, double> getCategoryData(TransactionType type,
      {int? month, int? year}) {
    final data = <String, double>{};
    var filtered = transactions.where((t) => t.type == type);
    if (month != null && year != null) {
      filtered =
          filtered.where((t) => t.date.month == month && t.date.year == year);
    }
    for (var tx in filtered) {
      data[tx.category] = (data[tx.category] ?? 0) + tx.amount;
    }
    return data;
  }

  List<Map<String, dynamic>> getAllMonthlyFinancialHealth() {
    final now = DateTime.now();
    final monthKeys = <String>{'${now.year}-${now.month}'};

    for (var tx in transactions) {
      monthKeys.add('${tx.date.year}-${tx.date.month}');
    }

    final parsedMonths = monthKeys.map((key) {
      final parts = key.split('-');
      return {
        'year': int.parse(parts[0]),
        'month': int.parse(parts[1]),
      };
    }).toList();

    // Sort descending by year, then by month
    parsedMonths.sort((a, b) {
      if (b['year'] != a['year']) {
        return b['year']!.compareTo(a['year']!);
      }
      return b['month']!.compareTo(a['month']!);
    });

    final results = <Map<String, dynamic>>[];
    for (var m in parsedMonths) {
      final year = m['year']!;
      final month = m['month']!;
      final income = getMonthlyTotal(TransactionType.income, month, year);
      final expense = getMonthlyTotal(TransactionType.expense, month, year);
      final savings = income - expense;
      final savingsRate = income > 0 ? (savings / income) * 100 : 0.0;
      final isCurrent = (year == now.year && month == now.month);

      results.add({
        'year': year,
        'month': month,
        'income': income,
        'expense': expense,
        'savings': savings,
        'savingsRate': savingsRate,
        'isCurrentMonth': isCurrent,
      });
    }

    return results;
  }
}
