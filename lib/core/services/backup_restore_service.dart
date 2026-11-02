// HiveList is required to preserve the existing list-to-item box relationships.
// ignore_for_file: experimental_member_use

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:core_database/core_database.dart';
import 'package:ms_finance/features/finance/data/models/finance_models.dart';
import 'package:ms_finance/features/shopping_market/models/market_models.dart';
import 'package:ms_finance/features/shopping_market/models/comparator_models.dart';
import 'package:ms_finance/core/utils/storage_utils.dart';

class BackupSummary {
  final int transactionCount;
  final int trashedCount;
  final int walletCount;
  final int categoryCount;
  final int assetCount;
  final int marketListCount;
  final int comparatorListCount;
  final DateTime? latestTransactionDate;
  final DateTime? backupDate;
  final int version;

  BackupSummary({
    required this.transactionCount,
    required this.trashedCount,
    required this.walletCount,
    required this.categoryCount,
    required this.assetCount,
    this.marketListCount = 0,
    this.comparatorListCount = 0,
    this.latestTransactionDate,
    this.backupDate,
    this.version = 1,
  });
}

class BackupRestoreService {
  static Future<Box> _getAssetBox() async {
    return LocalPersistence.openEncryptedBox<dynamic>('assets');
  }

  static Map<String, dynamic> _encodeMarketList(MarketList list) => {
    'title': list.title,
    'createdAt': list.createdAt.toIso8601String(),
    'items':
        list.items
            ?.map(
              (item) => {
                'name': item.name,
                'quantity': item.quantity,
                'unit': item.unit,
                'unitPrice': item.unitPrice,
                'isBought': item.isBought,
              },
            )
            .toList() ??
        <Map<String, dynamic>>[],
  };

  static Map<String, dynamic> _encodeComparatorList(ComparatorList list) => {
    'title': list.title,
    'createdAt': list.createdAt.toIso8601String(),
    'items':
        list.items
            ?.map(
              (item) => {
                'name': item.name,
                'quantity': item.quantity,
                'unit': item.unit,
                'totalPrice': item.totalPrice,
              },
            )
            .toList() ??
        <Map<String, dynamic>>[],
  };

  static List<Map<String, dynamic>>? _parseListPayload(
    dynamic raw, {
    required bool comparator,
  }) {
    if (raw is! List) return null;
    final result = <Map<String, dynamic>>[];
    for (final value in raw) {
      if (value is! Map) return null;
      final list = Map<String, dynamic>.from(value);
      final title = list['title']?.toString().trim() ?? '';
      final createdAt = DateTime.tryParse(list['createdAt']?.toString() ?? '');
      final rawItems = list['items'];
      if (title.isEmpty || createdAt == null || rawItems is! List) return null;
      final items = <Map<String, dynamic>>[];
      for (final rawItem in rawItems) {
        if (rawItem is! Map) return null;
        final item = Map<String, dynamic>.from(rawItem);
        final name = item['name']?.toString().trim() ?? '';
        final unit = item['unit']?.toString() ?? '';
        final quantity = (item['quantity'] as num?)?.toDouble();
        final price = (item[comparator ? 'totalPrice' : 'unitPrice'] as num?)
            ?.toDouble();
        if (name.isEmpty ||
            quantity == null ||
            !quantity.isFinite ||
            quantity < 0 ||
            price == null ||
            !price.isFinite ||
            price < 0 ||
            (!comparator && item['isBought'] is! bool)) {
          return null;
        }
        items.add({
          'name': name,
          'unit': unit,
          'quantity': quantity,
          (comparator ? 'totalPrice' : 'unitPrice'): price,
          if (!comparator) 'isBought': item['isBought'],
        });
      }
      result.add({
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'items': items,
      });
    }
    return result;
  }

  static Future<void> _replaceMarketLists(
    List<Map<String, dynamic>> data,
    Box<MarketList> listsBox,
    Box<MarketItem> itemsBox,
  ) async {
    await listsBox.clear();
    await itemsBox.clear();
    for (final record in data) {
      final items = (record['items'] as List)
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => MarketItem(
              name: item['name'] as String,
              quantity: item['quantity'] as double,
              unit: item['unit'] as String,
              unitPrice: item['unitPrice'] as double,
              isBought: item['isBought'] as bool,
            ),
          )
          .toList();
      await itemsBox.addAll(items);
      await listsBox.add(
        MarketList(
          title: record['title'] as String,
          createdAt: DateTime.parse(record['createdAt'] as String),
          items: HiveList<MarketItem>(itemsBox, objects: items),
        ),
      );
    }
  }

  static Future<void> _replaceComparatorLists(
    List<Map<String, dynamic>> data,
    Box<ComparatorList> listsBox,
    Box<ComparatorItem> itemsBox,
  ) async {
    await listsBox.clear();
    await itemsBox.clear();
    for (final record in data) {
      final items = (record['items'] as List)
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => ComparatorItem(
              name: item['name'] as String,
              quantity: item['quantity'] as double,
              unit: item['unit'] as String,
              totalPrice: item['totalPrice'] as double,
            ),
          )
          .toList();
      await itemsBox.addAll(items);
      await listsBox.add(
        ComparatorList(
          title: record['title'] as String,
          createdAt: DateTime.parse(record['createdAt'] as String),
          items: HiveList<ComparatorItem>(itemsBox, objects: items),
        ),
      );
    }
  }

  // Export all local user data to JSON (version 4 adds shopping lists).
  static Future<String?> exportToJson() async {
    try {
      final txBox = Hive.box<Transaction>('transactions');
      final walletBox = Hive.box<Wallet>('wallets');
      final catBox = Hive.box<Category>('categories');
      final assetBox = await _getAssetBox();
      final marketListsBox = Hive.box<MarketList>('market_lists');
      final comparatorListsBox = Hive.box<ComparatorList>('comparator_lists');

      final data = {
        'version': 4,
        'backupDate': DateTime.now().toIso8601String(),
        'transactions': txBox.values
            .map(
              (t) => {
                'id': t.id,
                'amount': t.amount,
                'category': t.category,
                'date': t.date.toIso8601String(),
                'note': t.note,
                'type': t.type.index,
                'walletId': t.walletId,
                'toWalletId': t.toWalletId,
                'isDeleted': t.isDeleted,
                'deletedAt': t.deletedAt?.toIso8601String(),
              },
            )
            .toList(),
        'wallets': walletBox.values
            .map(
              (w) => {
                'id': w.id,
                'name': w.name,
                'balance': w.balance,
                'icon': w.icon,
              },
            )
            .toList(),
        'categories': catBox.values
            .map((c) => {'id': c.id, 'name': c.name, 'type': c.type.index})
            .toList(),
        'assets': assetBox.values.map((a) {
          if (a is Map) return Map<String, dynamic>.from(a);
          return a;
        }).toList(),
        'marketLists': marketListsBox.values.map(_encodeMarketList).toList(),
        'comparatorLists': comparatorListsBox.values
            .map(_encodeComparatorList)
            .toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getApplicationDocumentsDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${dir.path}/ms_finance_backup_$dateStr.json';

      final file = File(filePath);
      await file.writeAsString(jsonString, flush: true);

      await StorageUtils.saveFileToCustomFolder(
        filePath,
        'ms_finance_backup_$dateStr.json',
      );
      return filePath;
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    }
  }

  // Export Transactions & Assets to CSV
  static Future<String?> exportToCsv() async {
    try {
      final txBox = Hive.box<Transaction>('transactions');
      final assetBox = await _getAssetBox();
      final buffer = StringBuffer();

      buffer.writeln('--- TRANSACTIONS ---');
      buffer.writeln('ID,Amount,Type,Category,Date,WalletID,Note,IsDeleted');

      for (var t in txBox.values.where((t) => !t.isDeleted)) {
        buffer.writeln(
          '"${t.id}",${t.amount},"${t.type.name}","${t.category}","${t.date.toIso8601String()}","${t.walletId}","${t.note.replaceAll('"', '""')}","${t.isDeleted}"',
        );
      }

      if (assetBox.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('--- ASSETS ---');
        buffer.writeln('ID,Name,Amount,LastModified');
        for (var a in assetBox.values) {
          if (a is Map) {
            final id = a['id']?.toString() ?? '';
            final name = (a['name']?.toString() ?? '').replaceAll('"', '""');
            final amount = (a['amount'] as num?)?.toDouble() ?? 0.0;
            final lastModified = a['lastModified']?.toString() ?? '';
            buffer.writeln('"$id","$name",$amount,"$lastModified"');
          }
        }
      }

      final dir = await getApplicationDocumentsDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${dir.path}/ms_finance_transactions_$dateStr.csv';

      final file = File(filePath);
      await file.writeAsString(buffer.toString(), flush: true);

      await StorageUtils.saveFileToCustomFolder(
        filePath,
        'ms_finance_transactions_$dateStr.csv',
      );
      return filePath;
    } catch (e) {
      debugPrint('CSV Export error: $e');
      return null;
    }
  }

  // Parse backup file and return summary for pre-restore confirmation (Schema Version Aware)
  static Future<BackupSummary?> analyzeBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      String jsonString;
      try {
        jsonString = await file.readAsString();
      } catch (_) {
        final bytes = await file.readAsBytes();
        jsonString = utf8.decode(bytes, allowMalformed: true);
      }

      if (jsonString.startsWith('\uFEFF')) {
        jsonString = jsonString.substring(1);
      }
      jsonString = jsonString.trim();

      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) return null;
      final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);

      if (!data.containsKey('transactions') &&
          !data.containsKey('wallets') &&
          !data.containsKey('categories') &&
          !data.containsKey('assets') &&
          !data.containsKey('marketLists') &&
          !data.containsKey('comparatorLists')) {
        return null;
      }

      final version = (data['version'] as int?) ?? 1;
      final txs = data['transactions'] as List? ?? [];
      final wallets = data['wallets'] as List? ?? [];
      final categories = data['categories'] as List? ?? [];
      final assets = data['assets'] as List? ?? [];
      final marketLists = data['marketLists'] as List? ?? [];
      final comparatorLists = data['comparatorLists'] as List? ?? [];
      final backupDateStr = data['backupDate'] as String?;
      final backupDate = backupDateStr != null
          ? DateTime.tryParse(backupDateStr)
          : null;

      int activeCount = 0;
      int trashedCount = 0;
      DateTime? latestDate;

      for (var t in txs) {
        if (t is Map) {
          final isDel = t['isDeleted'] == true;
          if (isDel) {
            trashedCount++;
          } else {
            activeCount++;
          }

          if (t['date'] != null) {
            final date = DateTime.tryParse(t['date'].toString());
            if (date != null) {
              if (latestDate == null || date.isAfter(latestDate)) {
                latestDate = date;
              }
            }
          }
        }
      }

      return BackupSummary(
        transactionCount: activeCount,
        trashedCount: trashedCount,
        walletCount: wallets.length,
        categoryCount: categories.length,
        assetCount: assets.length,
        marketListCount: marketLists.length,
        comparatorListCount: comparatorLists.length,
        latestTransactionDate: latestDate,
        backupDate: backupDate,
        version: version,
      );
    } catch (e) {
      debugPrint('Analyze backup error: $e');
      return null;
    }
  }

  // Restore backup from JSON file (Supports Schema Migration / Versioning)
  static Future<bool> restoreFromJson(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      String jsonString;
      try {
        jsonString = await file.readAsString();
      } catch (_) {
        final bytes = await file.readAsBytes();
        jsonString = utf8.decode(bytes, allowMalformed: true);
      }

      if (jsonString.startsWith('\uFEFF')) {
        jsonString = jsonString.substring(1);
      }
      jsonString = jsonString.trim();

      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) return false;
      final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);

      final version = (data['version'] as int?) ?? 1;
      if (version < 1 || version > 4) return false;

      final transactions = <Transaction>[];
      for (final value in data['transactions'] as List? ?? const []) {
        if (value is! Map) return false;
        final item = Map<String, dynamic>.from(value);
        final typeIndex = item['type'] as int? ?? -1;
        final amount = (item['amount'] as num?)?.toDouble();
        final date = DateTime.tryParse(item['date']?.toString() ?? '');
        final id = item['id']?.toString() ?? '';
        final walletId = item['walletId']?.toString() ?? '';
        if (id.isEmpty ||
            walletId.isEmpty ||
            amount == null ||
            !amount.isFinite ||
            amount <= 0 ||
            date == null ||
            typeIndex < 0 ||
            typeIndex >= TransactionType.values.length) {
          return false;
        }
        final isDeleted = version >= 2 && item['isDeleted'] == true;
        transactions.add(
          Transaction(
            id: id,
            amount: amount,
            category: item['category']?.toString() ?? '',
            date: date,
            note: item['note']?.toString() ?? '',
            type: TransactionType.values[typeIndex],
            walletId: walletId,
            toWalletId: item['toWalletId']?.toString(),
            isDeleted: isDeleted,
            deletedAt: version >= 2 && item['deletedAt'] != null
                ? DateTime.tryParse(item['deletedAt'].toString())
                : null,
          ),
        );
      }

      final wallets = <Wallet>[];
      for (final value in data['wallets'] as List? ?? const []) {
        if (value is! Map) return false;
        final item = Map<String, dynamic>.from(value);
        final id = item['id']?.toString() ?? '';
        final balance = (item['balance'] as num?)?.toDouble();
        if (id.isEmpty || balance == null || !balance.isFinite) return false;
        wallets.add(
          Wallet(
            id: id,
            name: item['name']?.toString() ?? '',
            balance: balance,
            icon: item['icon']?.toString() ?? 'account_balance_wallet',
          ),
        );
      }

      final categories = <Category>[];
      for (final value in data['categories'] as List? ?? const []) {
        if (value is! Map) return false;
        final item = Map<String, dynamic>.from(value);
        final typeIndex = item['type'] as int? ?? -1;
        final id = item['id']?.toString() ?? '';
        if (id.isEmpty ||
            typeIndex < 0 ||
            typeIndex >= TransactionType.values.length) {
          return false;
        }
        categories.add(
          Category(
            id: id,
            name: item['name']?.toString() ?? '',
            type: TransactionType.values[typeIndex],
          ),
        );
      }

      final assets = <Map<String, dynamic>>[];
      for (final value in data['assets'] as List? ?? const []) {
        if (value is! Map) return false;
        final item = Map<String, dynamic>.from(value);
        if ((item['id']?.toString() ?? '').isEmpty) return false;
        assets.add(item);
      }

      final hasShoppingData =
          data.containsKey('marketLists') ||
          data.containsKey('comparatorLists');
      if ((version >= 4 && !hasShoppingData) ||
          data.containsKey('marketLists') !=
              data.containsKey('comparatorLists')) {
        return false;
      }
      final marketLists = hasShoppingData
          ? _parseListPayload(data['marketLists'], comparator: false)
          : null;
      final comparatorLists = hasShoppingData
          ? _parseListPayload(data['comparatorLists'], comparator: true)
          : null;
      if (hasShoppingData && (marketLists == null || comparatorLists == null)) {
        return false;
      }

      final txBox = Hive.box<Transaction>('transactions');
      final walletBox = Hive.box<Wallet>('wallets');
      final catBox = Hive.box<Category>('categories');
      final assetBox = await _getAssetBox();
      final marketListsBox = hasShoppingData
          ? Hive.box<MarketList>('market_lists')
          : null;
      final marketItemsBox = hasShoppingData
          ? Hive.box<MarketItem>('market_items')
          : null;
      final comparatorListsBox = hasShoppingData
          ? Hive.box<ComparatorList>('comparator_lists')
          : null;
      final comparatorItemsBox = hasShoppingData
          ? Hive.box<ComparatorItem>('comparator_items')
          : null;

      final oldTransactions = Map<dynamic, Transaction>.from(txBox.toMap());
      final oldWallets = Map<dynamic, Wallet>.from(walletBox.toMap());
      final oldCategories = Map<dynamic, Category>.from(catBox.toMap());
      final oldAssets = Map<dynamic, dynamic>.from(assetBox.toMap());
      final oldMarketLists = hasShoppingData
          ? marketListsBox!.values.map(_encodeMarketList).toList()
          : null;
      final oldComparatorLists = hasShoppingData
          ? comparatorListsBox!.values.map(_encodeComparatorList).toList()
          : null;

      try {
        await txBox.clear();
        await walletBox.clear();
        await catBox.clear();
        await assetBox.clear();
        await txBox.putAll({for (final tx in transactions) tx.id: tx});
        await walletBox.putAll({
          for (final wallet in wallets) wallet.id: wallet,
        });
        await catBox.putAll({
          for (final category in categories) category.id: category,
        });
        await assetBox.putAll({for (final asset in assets) asset['id']: asset});
        if (hasShoppingData) {
          await _replaceMarketLists(
            marketLists!,
            marketListsBox!,
            marketItemsBox!,
          );
          await _replaceComparatorLists(
            comparatorLists!,
            comparatorListsBox!,
            comparatorItemsBox!,
          );
        }
        return true;
      } catch (error, stackTrace) {
        await txBox.clear();
        await walletBox.clear();
        await catBox.clear();
        await assetBox.clear();
        await txBox.putAll(oldTransactions);
        await walletBox.putAll(oldWallets);
        await catBox.putAll(oldCategories);
        await assetBox.putAll(oldAssets);
        if (hasShoppingData) {
          await _replaceMarketLists(
            oldMarketLists!,
            marketListsBox!,
            marketItemsBox!,
          );
          await _replaceComparatorLists(
            oldComparatorLists!,
            comparatorListsBox!,
            comparatorItemsBox!,
          );
        }
        Error.throwWithStackTrace(error, stackTrace);
      }
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }
}
