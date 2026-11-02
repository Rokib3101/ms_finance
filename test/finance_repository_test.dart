import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ms_finance/features/finance/data/models/finance_models.dart';
import 'package:ms_finance/features/finance/data/repositories/hive_finance_repository.dart';

void main() {
  late Directory hiveDirectory;
  late HiveFinanceRepository repository;
  late Box<Transaction> transactions;
  late Box<Wallet> wallets;
  late Box<Category> categories;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('ms_finance_test_');
    Hive.init(hiveDirectory.path);
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(WalletAdapter());
    Hive.registerAdapter(CategoryAdapter());
  });

  setUp(() async {
    transactions = await Hive.openBox<Transaction>('transactions');
    wallets = await Hive.openBox<Wallet>('wallets');
    categories = await Hive.openBox<Category>('categories');
    await transactions.clear();
    await wallets.clear();
    await categories.clear();
    await wallets.putAll({
      'cash': Wallet(id: 'cash', name: 'Cash', balance: 100, icon: 'money'),
      'bank': Wallet(
        id: 'bank',
        name: 'Bank',
        balance: 200,
        icon: 'account_balance',
      ),
    });
    repository = HiveFinanceRepository();
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test(
    'transfer updates both wallets and delete/restore reverses it',
    () async {
      final transfer = Transaction(
        id: 'transfer-1',
        amount: 25,
        category: 'Transfer',
        date: DateTime(2026, 1, 1),
        note: '',
        type: TransactionType.transfer,
        walletId: 'cash',
        toWalletId: 'bank',
      );

      await repository.addTransaction(transfer);
      expect(wallets.get('cash')!.balance, 75);
      expect(wallets.get('bank')!.balance, 225);

      await repository.deleteTransaction(transfer);
      expect(wallets.get('cash')!.balance, 100);
      expect(wallets.get('bank')!.balance, 200);
      expect(repository.getTrashedTransactions(), hasLength(1));

      await repository.restoreTransaction(transfer);
      expect(wallets.get('cash')!.balance, 75);
      expect(wallets.get('bank')!.balance, 225);
      expect(repository.getTransactions(), hasLength(1));
    },
  );

  test(
    'permanent delete of an active income restores its wallet balance',
    () async {
      final income = Transaction(
        id: 'income-1',
        amount: 50,
        category: 'Salary',
        date: DateTime(2026, 1, 1),
        note: '',
        type: TransactionType.income,
        walletId: 'cash',
      );

      await repository.addTransaction(income);
      expect(wallets.get('cash')!.balance, 150);

      await repository.permanentDeleteTransaction(income);
      expect(wallets.get('cash')!.balance, 100);
      expect(transactions.containsKey(income.id), isFalse);
    },
  );

  test(
    'selective income clearing preserves expenses and recalculates balance',
    () async {
      final income = Transaction(
        id: 'income-2',
        amount: 80,
        category: 'Salary',
        date: DateTime(2026, 1, 12),
        note: '',
        type: TransactionType.income,
        walletId: 'cash',
      );
      final expense = Transaction(
        id: 'expense-1',
        amount: 30,
        category: 'Food',
        date: DateTime(2026, 1, 13),
        note: '',
        type: TransactionType.expense,
        walletId: 'cash',
      );
      await repository.addTransaction(income);
      await repository.addTransaction(expense);

      await repository.clearSelectiveData(
        month: 1,
        year: 2026,
        clearIncome: true,
      );

      expect(repository.getTransactions().map((tx) => tx.id), ['expense-1']);
      expect(wallets.get('cash')!.balance, 70);
    },
  );

  test(
    'emptying trash leaves balances unchanged after soft deletion',
    () async {
      final expense = Transaction(
        id: 'expense-2',
        amount: 20,
        category: 'Food',
        date: DateTime(2026, 1, 14),
        note: '',
        type: TransactionType.expense,
        walletId: 'cash',
      );
      await repository.addTransaction(expense);
      await repository.deleteTransaction(expense);
      expect(wallets.get('cash')!.balance, 100);

      await repository.emptyTrash();
      expect(wallets.get('cash')!.balance, 100);
      expect(transactions.isEmpty, isTrue);
    },
  );
}
