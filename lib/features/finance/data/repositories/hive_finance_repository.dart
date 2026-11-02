import 'package:hive/hive.dart';
import '../../domain/repositories/finance_repository.dart';
import '../models/finance_models.dart';

class HiveFinanceRepository implements FinanceRepository {
  Box<Transaction> get _transactionBox => Hive.box<Transaction>('transactions');
  Box<Wallet> get _walletBox => Hive.box<Wallet>('wallets');
  Box<Category> get _categoryBox => Hive.box<Category>('categories');

  Future<void> _restoreContents<T>(Box<T> box, Map<dynamic, T> contents) async {
    await box.clear();
    await box.putAll(contents);
  }

  @override
  List<Transaction> getTransactions() {
    return _transactionBox.values.where((tx) => !tx.isDeleted).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  List<Transaction> getTrashedTransactions() {
    return _transactionBox.values.where((tx) => tx.isDeleted).toList()
      ..sort(
          (a, b) => (b.deletedAt ?? b.date).compareTo(a.deletedAt ?? a.date));
  }

  @override
  List<Wallet> getWallets() {
    return _walletBox.values.toList();
  }

  @override
  List<Category> getCategories() {
    return _categoryBox.values.toList();
  }

  @override
  Future<void> initDefaultWallets() async {
    if (_walletBox.isEmpty) {
      final defaultWallets = [
        Wallet(id: 'bank', name: 'Bank', balance: 0, icon: 'account_balance'),
        Wallet(id: 'cash', name: 'Cash', balance: 0, icon: 'money'),
      ];
      for (var w in defaultWallets) {
        await _walletBox.put(w.id, w);
      }
    }
  }

  @override
  Future<void> initDefaultCategories() async {
    if (_categoryBox.isEmpty) {
      final defaultCategories = [
        Category(
            id: 'inc_01_salary', name: 'Salary', type: TransactionType.income),
        Category(
            id: 'inc_02_business',
            name: 'Business',
            type: TransactionType.income),
        Category(
            id: 'exp_01_food', name: 'Food', type: TransactionType.expense),
        Category(
            id: 'exp_02_medicine',
            name: 'Medicine',
            type: TransactionType.expense),
        Category(
            id: 'exp_03_transport',
            name: 'Transport',
            type: TransactionType.expense),
        Category(
            id: 'exp_04_utilities',
            name: 'Utilities',
            type: TransactionType.expense),
        Category(
            id: 'exp_05_others', name: 'Others', type: TransactionType.expense),
      ];
      for (var c in defaultCategories) {
        await _categoryBox.put(c.id, c);
      }
    }
  }

  @override
  Future<void> addCategory(Category category) async {
    await _categoryBox.put(category.id, category);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _categoryBox.delete(categoryId);
  }

  @override
  Future<void> addWallet(Wallet wallet) async {
    await _walletBox.put(wallet.id, wallet);
  }

  @override
  Future<void> updateWallet(Wallet wallet) async {
    await _walletBox.put(wallet.id, wallet);
  }

  @override
  Future<void> deleteWallet(String walletId) async {
    final hasTransactions = _transactionBox.values.any(
      (tx) => tx.walletId == walletId || tx.toWalletId == walletId,
    );
    if (hasTransactions) {
      throw StateError('This wallet still has transaction history.');
    }
    await _walletBox.delete(walletId);
  }

  @override
  Future<void> addTransaction(Transaction tx) async {
    if (_transactionBox.containsKey(tx.id)) {
      throw StateError('A transaction with id ${tx.id} already exists.');
    }
    if (!tx.amount.isFinite || tx.amount <= 0) {
      throw ArgumentError.value(
          tx.amount, 'amount', 'Must be a positive finite amount.');
    }
    await _commitTransaction(tx, null);
  }

  @override
  Future<void> deleteTransaction(Transaction tx) async {
    final stored = _transactionBox.get(tx.id);
    if (stored == null || stored.isDeleted) return;
    await _commitTransaction(
      stored.copyWith(isDeleted: true, deletedAt: DateTime.now()),
      stored,
    );
  }

  @override
  Future<void> restoreTransaction(Transaction tx) async {
    final stored = _transactionBox.get(tx.id);
    if (stored == null || !stored.isDeleted) return;
    await _commitTransaction(
      stored.copyWith(isDeleted: false, deletedAt: null),
      stored,
    );
  }

  @override
  Future<void> permanentDeleteTransaction(Transaction tx) async {
    final stored = _transactionBox.get(tx.id);
    if (stored == null) return;
    await _commitTransaction(null, stored);
  }

  /// Keeps the ledger entry and cached wallet balances in sync. Hive cannot
  /// transact across boxes, so failed writes are compensated from snapshots.
  Future<void> _commitTransaction(
    Transaction? next,
    Transaction? previous, {
    bool updateBalances = true,
  }) async {
    final deltas = <String, double>{};
    void addEffects(Transaction tx, double multiplier) {
      if (tx.isDeleted) return;
      switch (tx.type) {
        case TransactionType.income:
          deltas.update(tx.walletId, (value) => value + tx.amount * multiplier,
              ifAbsent: () => tx.amount * multiplier);
          break;
        case TransactionType.expense:
          deltas.update(tx.walletId, (value) => value - tx.amount * multiplier,
              ifAbsent: () => -tx.amount * multiplier);
          break;
        case TransactionType.transfer:
          final targetId = tx.toWalletId;
          if (targetId == null || targetId == tx.walletId) {
            throw ArgumentError('A transfer requires two different wallets.');
          }
          deltas.update(tx.walletId, (value) => value - tx.amount * multiplier,
              ifAbsent: () => -tx.amount * multiplier);
          deltas.update(targetId, (value) => value + tx.amount * multiplier,
              ifAbsent: () => tx.amount * multiplier);
          break;
      }
    }

    if (updateBalances) {
      if (previous != null) addEffects(previous, -1);
      if (next != null) addEffects(next, 1);
    }

    final oldWallets = <String, Wallet>{};
    final nextWallets = <String, Wallet>{};
    for (final entry in deltas.entries) {
      if (entry.value == 0) continue;
      final wallet = _walletBox.get(entry.key);
      if (wallet == null) {
        throw StateError('Wallet ${entry.key} no longer exists.');
      }
      oldWallets[entry.key] = wallet;
      nextWallets[entry.key] =
          wallet.copyWith(balance: wallet.balance + entry.value);
    }

    try {
      for (final entry in nextWallets.entries) {
        await _walletBox.put(entry.key, entry.value);
      }
      if (next == null) {
        await _transactionBox.delete(previous!.id);
      } else {
        await _transactionBox.put(next.id, next);
      }
    } catch (error, stackTrace) {
      for (final entry in oldWallets.entries) {
        await _walletBox.put(entry.key, entry.value);
      }
      if (previous == null) {
        await _transactionBox.delete(next!.id);
      } else {
        await _transactionBox.put(previous.id, previous);
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<void> emptyTrash() async {
    final trashed = getTrashedTransactions();
    final oldTransactions =
        Map<dynamic, Transaction>.from(_transactionBox.toMap());
    try {
      for (final tx in trashed) {
        await permanentDeleteTransaction(tx);
      }
    } catch (error, stackTrace) {
      await _restoreContents(_transactionBox, oldTransactions);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<void> clearSelectiveData({
    int? month,
    int? year,
    bool clearIncome = false,
    bool clearExpense = false,
    bool clearWallets = false,
  }) async {
    final allTransactions = _transactionBox.values.toList();
    List<Transaction> targetsToDelete = [];

    for (var tx in allTransactions) {
      bool matchesMonth = (month == null || year == null) ||
          (tx.date.month == month && tx.date.year == year);

      if (!matchesMonth) continue;

      if (tx.type == TransactionType.income && clearIncome) {
        targetsToDelete.add(tx);
      } else if (tx.type == TransactionType.expense && clearExpense) {
        targetsToDelete.add(tx);
      } else if (tx.type == TransactionType.transfer && clearWallets) {
        targetsToDelete.add(tx);
      }
    }

    final oldTransactions =
        Map<dynamic, Transaction>.from(_transactionBox.toMap());
    final oldWallets = Map<dynamic, Wallet>.from(_walletBox.toMap());
    try {
      for (final tx in targetsToDelete) {
        if (clearWallets) {
          await _commitTransaction(null, tx, updateBalances: false);
        } else {
          await permanentDeleteTransaction(tx);
        }
      }

      if (clearWallets) {
        for (final wallet in _walletBox.values.toList()) {
          await _walletBox.put(wallet.id, wallet.copyWith(balance: 0));
        }
      }
    } catch (error, stackTrace) {
      await _restoreContents(_transactionBox, oldTransactions);
      await _restoreContents(_walletBox, oldWallets);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<void> clearAllTransactions() async {
    await clearSelectiveData(
      clearIncome: true,
      clearExpense: true,
      clearWallets: true,
    );
  }
}
