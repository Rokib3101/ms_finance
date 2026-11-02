import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:core_database/core_database.dart';
import 'package:ms_finance/core/theme/theme_provider.dart';
import 'package:ms_finance/core/security/app_lock_service.dart';
import 'package:ms_finance/core/security/app_lock_guard.dart';
import 'package:ms_finance/core/navigation/app_router.dart';
import 'package:ms_finance/features/finance/data/models/finance_models.dart';
import 'package:ms_finance/features/shopping_market/models/market_models.dart';
import 'package:ms_finance/features/shopping_market/models/comparator_models.dart';
import 'package:ms_finance/features/finance/presentation/providers/finance_provider.dart';
import 'package:ms_finance/features/finance/data/repositories/hive_finance_repository.dart';
import 'package:ms_finance/features/finance/presentation/providers/asset_provider.dart';
import 'package:ms_finance/features/finance/screens/finance_home_screen.dart';
import 'package:ms_finance/features/finance/screens/finance_dashboard.dart';
import 'package:ms_finance/features/finance/screens/finance_settings_screen.dart';
import 'package:ms_finance/features/finance/screens/transaction_entry_screen.dart';
import 'package:ms_finance/features/finance/screens/transaction_history_screen.dart';
import 'package:ms_finance/features/finance/screens/smart_insights_screen.dart';
import 'package:ms_finance/features/finance/screens/wallet_management_screen.dart';
import 'package:ms_finance/features/finance/screens/category_management_screen.dart';
import 'package:ms_finance/features/finance/screens/trash_management_screen.dart';
import 'package:ms_finance/features/finance/screens/asset_list_screen.dart';
import 'package:ms_finance/features/finance/screens/monthly_summary_screen.dart';
import 'package:ms_finance/features/cash_counter/presentation/screens/cash_counter_screen.dart';
import 'package:ms_finance/features/shopping_market/presentation/screens/shopping_list_screen.dart';
import 'package:ms_finance/features/shopping_market/presentation/screens/unit_price_comparator_screen.dart';
import 'package:ms_finance/features/shopping_market/presentation/screens/market_detail_screen.dart';
import 'package:ms_finance/features/shopping_market/presentation/screens/unit_price_comparator_detail_screen.dart';
import 'package:ms_finance/features/dashboard/presentation/screens/about_screen.dart';
import 'package:ms_finance/features/dashboard/presentation/screens/social_media_screen.dart';
import 'package:ms_finance/features/dashboard/presentation/screens/privacy_policy_screen.dart';
import 'package:ms_finance/features/dashboard/presentation/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('MS Finance Error: ${details.exception}');
  };

  await LocalPersistence.init();

  void registerAdapter<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  registerAdapter(TransactionTypeAdapter());
  registerAdapter(TransactionAdapter());
  registerAdapter(WalletAdapter());
  registerAdapter(CategoryAdapter());
  registerAdapter(MarketItemAdapter());
  registerAdapter(MarketListAdapter());
  registerAdapter(ComparatorItemAdapter());
  registerAdapter(ComparatorListAdapter());

  await LocalPersistence.openEncryptedBox<Transaction>('transactions');
  await LocalPersistence.openEncryptedBox<Wallet>('wallets');
  await LocalPersistence.openEncryptedBox<Category>('categories');

  await LocalPersistence.openEncryptedBox<MarketList>('market_lists');
  await LocalPersistence.openEncryptedBox<MarketItem>('market_items');
  await LocalPersistence.openEncryptedBox<ComparatorList>('comparator_lists');
  await LocalPersistence.openEncryptedBox<ComparatorItem>('comparator_items');
  await LocalPersistence.openEncryptedBox<dynamic>('assets');

  // Seed required finance data before providers and screens can read it.
  final financeRepository = HiveFinanceRepository();
  await financeRepository.initDefaultWallets();
  await financeRepository.initDefaultCategories();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => AssetProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppLockService()),
      ],
      child: const MSFinanceApp(),
    ),
  );
}

class MSFinanceApp extends StatelessWidget {
  const MSFinanceApp({super.key});

  static final GoRouter _router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const FinanceHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.socialMedia,
        builder: (context, state) => const SocialMediaScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.finance,
        builder: (context, state) =>
            const AppLockGuard(child: FinanceDashboard()),
      ),
      GoRoute(
        path: AppRoutes.cashCounter,
        builder: (context, state) => const CashCounterScreen(),
      ),
      GoRoute(
        path: AppRoutes.shopping,
        builder: (context, state) => const ShoppingListScreen(),
      ),
      GoRoute(
        path: AppRoutes.shoppingList,
        builder: (context, state) => const ShoppingListScreen(),
      ),
      GoRoute(
        path: AppRoutes.comparator,
        builder: (context, state) => const UnitPriceComparatorScreen(),
      ),
      GoRoute(
        path: AppRoutes.unitPrice,
        builder: (context, state) => const UnitPriceComparatorScreen(),
      ),
      GoRoute(
        path: AppRoutes.financeSettings,
        builder: (context, state) => const FinanceSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.financeTransactionEntry,
        builder: (context, state) => const TransactionEntryScreen(),
      ),
      GoRoute(
        path: AppRoutes.financeHistory,
        builder: (context, state) => const TransactionHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.financeInsights,
        builder: (context, state) => const SmartInsightsScreen(),
      ),
      GoRoute(
        path: AppRoutes.financeWallets,
        builder: (context, state) => const WalletManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.financeCategories,
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.financeTrash,
        builder: (context, state) => const TrashManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.financeAssets,
        builder: (context, state) => const AssetListScreen(),
      ),
      GoRoute(
        path: AppRoutes.financeMonthlySummary,
        builder: (context, state) => const MonthlySummaryScreen(),
      ),
      GoRoute(
        path: AppRoutes.shoppingListDetail,
        builder: (context, state) {
          final list = state.extra as MarketList;
          return MarketDetailScreen(marketList: list);
        },
      ),
      GoRoute(
        path: AppRoutes.unitPriceDetail,
        builder: (context, state) {
          final list = state.extra as ComparatorList;
          return UnitPriceComparatorDetailScreen(comparatorList: list);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp.router(
      title: 'MS Finance',
      debugShowCheckedModeBanner: false,
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
    );
  }
}
