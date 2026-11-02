import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'finance_models.g.dart';

@HiveType(typeId: 0)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
  @HiveField(2)
  transfer
}

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final double amount;
  @HiveField(2)
  final String category;
  @HiveField(3)
  final DateTime date;
  @HiveField(4)
  final String note;
  @HiveField(5)
  final TransactionType type;
  @HiveField(6)
  final String walletId;
  @HiveField(7)
  final String? toWalletId; // For transfers
  @HiveField(8)
  final bool isDeleted; // Soft delete / trash flag
  @HiveField(9)
  final DateTime? deletedAt; // Timestamp when moved to trash

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
    required this.type,
    required this.walletId,
    this.toWalletId,
    this.isDeleted = false,
    this.deletedAt,
  });

  factory Transaction.create({
    required double amount,
    required String category,
    required TransactionType type,
    required String walletId,
    String note = '',
    String? toWalletId,
  }) {
    return Transaction(
      id: const Uuid().v4(),
      amount: amount,
      category: category,
      date: DateTime.now(),
      note: note,
      type: type,
      walletId: walletId,
      toWalletId: toWalletId,
      isDeleted: false,
      deletedAt: null,
    );
  }

  Transaction copyWith({
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    TransactionType? type,
    String? walletId,
    String? toWalletId,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return Transaction(
      id: id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      type: type ?? this.type,
      walletId: walletId ?? this.walletId,
      toWalletId: toWalletId ?? this.toWalletId,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

@HiveType(typeId: 2)
class Wallet extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final double balance;
  @HiveField(3)
  final String icon;

  Wallet({
    required this.id,
    required this.name,
    required this.balance,
    required this.icon,
  });

  Wallet copyWith({double? balance, String? name}) {
    return Wallet(
      id: id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      icon: icon,
    );
  }
}

@HiveType(typeId: 6)
class Category extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final TransactionType type;

  Category({
    required this.id,
    required this.name,
    required this.type,
  });
}
