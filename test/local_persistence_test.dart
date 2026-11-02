import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:core_database/core_database.dart';
import 'package:ms_finance/features/finance/data/models/finance_models.dart';
import 'package:ms_finance/features/finance/data/repositories/hive_finance_repository.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('local_persistence_test_');
    Hive.init(tempDir.path);
    LocalPersistence.financeCipher = HiveAesCipher(Hive.generateSecureKey());
    LocalPersistence.isInitialized = true;

    void registerAdapter<T>(TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(adapter.typeId)) {
        Hive.registerAdapter(adapter);
      }
    }

    registerAdapter(TransactionTypeAdapter());
    registerAdapter(TransactionAdapter());
    registerAdapter(WalletAdapter());
    registerAdapter(CategoryAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('openEncryptedBox preserves data across app restarts (box re-opens)', () async {
    const boxName = 'test_encrypted_box';

    // First launch/session: open box, write data, close box.
    var box = await LocalPersistence.openEncryptedBox<String>(boxName);
    await box.put('k1', 'v1');
    await box.put('k2', 'v2');
    expect(box.get('k1'), 'v1');
    expect(box.get('k2'), 'v2');
    await box.close();

    // Second launch/session (simulating app exit and re-entry):
    var reopenedBox = await LocalPersistence.openEncryptedBox<String>(boxName);
    expect(reopenedBox.get('k1'), 'v1', reason: 'Data k1 should persist after re-opening encrypted box');
    expect(reopenedBox.get('k2'), 'v2', reason: 'Data k2 should persist after re-opening encrypted box');
    await reopenedBox.close();
  });

  test('restored finance transactions and wallets persist after closing and re-opening boxes', () async {
    var txBox = await LocalPersistence.openEncryptedBox<Transaction>('transactions');
    var walletBox = await LocalPersistence.openEncryptedBox<Wallet>('wallets');
    var catBox = await LocalPersistence.openEncryptedBox<Category>('categories');

    // Simulate restoring backup data
    await txBox.clear();
    await walletBox.clear();
    await catBox.clear();

    final restoredWallet = Wallet(id: 'bank_1', name: 'Main Bank', balance: 5000, icon: 'account_balance');
    final restoredTx = Transaction(
      id: 'tx_101',
      amount: 1500,
      category: 'Salary',
      date: DateTime(2026, 2, 1),
      note: 'January salary',
      type: TransactionType.income,
      walletId: 'bank_1',
    );

    await walletBox.put(restoredWallet.id, restoredWallet);
    await txBox.put(restoredTx.id, restoredTx);

    // Close all boxes to simulate exiting the app
    await txBox.close();
    await walletBox.close();
    await catBox.close();

    // Re-open boxes to simulate re-entering the app
    var reopenedTxBox = await LocalPersistence.openEncryptedBox<Transaction>('transactions');
    var reopenedWalletBox = await LocalPersistence.openEncryptedBox<Wallet>('wallets');

    expect(reopenedWalletBox.length, equals(1));
    expect(reopenedWalletBox.get('bank_1')?.balance, equals(5000));
    expect(reopenedTxBox.length, equals(1));
    expect(reopenedTxBox.get('tx_101')?.amount, equals(1500));

    final repo = HiveFinanceRepository();
    expect(repo.getWallets().first.balance, equals(5000));
    expect(repo.getTransactions().first.amount, equals(1500));

    await reopenedTxBox.close();
    await reopenedWalletBox.close();
  });
}
