import '../../data/models/finance_models.dart';

abstract class FinanceRepository {
  List<Transaction> getTransactions();
  List<Transaction> getTrashedTransactions();
  List<Wallet> getWallets();
  List<Category> getCategories();

  Future<void> initDefaultWallets();
  Future<void> initDefaultCategories();

  // Category
  Future<void> addCategory(Category category);
  Future<void> deleteCategory(String categoryId);

  // Wallet
  Future<void> addWallet(Wallet wallet);
  Future<void> updateWallet(Wallet wallet);
  Future<void> deleteWallet(String walletId);

  // Transaction
  Future<void> addTransaction(Transaction tx);
  Future<void> deleteTransaction(Transaction tx);
  Future<void> restoreTransaction(Transaction tx);
  Future<void> permanentDeleteTransaction(Transaction tx);
  Future<void> emptyTrash();
  Future<void> clearAllTransactions();
  Future<void> clearSelectiveData({
    int? month,
    int? year,
    bool clearIncome = false,
    bool clearExpense = false,
    bool clearWallets = false,
  });
}
