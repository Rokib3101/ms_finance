/// Canonical route paths used by feature screens.
///
/// The GoRouter instance is owned by the app in `main.dart`, which keeps one
/// route table.
abstract class AppRoutes {
  static const String home = '/';
  static const String about = '/about';
  static const String socialMedia = '/social-media';
  static const String privacyPolicy = '/privacy-policy';
  static const String settings = '/settings';
  static const String finance = '/finance';
  static const String cashCounter = '/cash-counter';
  static const String shopping = '/shopping';
  static const String shoppingList = '/shopping-list';
  static const String comparator = '/comparator';
  static const String unitPrice = '/unit-price';
  static const String financeSettings = '/finance/settings';
  static const String financeTransactionEntry = '/finance/transaction-entry';
  static const String financeHistory = '/finance/history';
  static const String financeInsights = '/finance/insights';
  static const String financeWallets = '/finance/wallets';
  static const String financeCategories = '/finance/categories';
  static const String financeTrash = '/finance/trash';
  static const String financeAssets = '/finance/assets';
  static const String financeMonthlySummary = '/finance/monthly-summary';
  static const String shoppingListDetail = '/shopping-list/detail';
  static const String unitPriceDetail = '/unit-price/detail';
}
