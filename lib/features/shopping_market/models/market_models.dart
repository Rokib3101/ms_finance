// HiveList is used to preserve the current on-disk relationship schema.
// ignore_for_file: experimental_member_use

import 'package:hive/hive.dart';

part 'market_models.g.dart';

@HiveType(typeId: 10)
class MarketItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double quantity;

  @HiveField(2)
  String unit; // e.g., kg, piece

  @HiveField(3)
  double unitPrice;

  @HiveField(4)
  bool isBought;

  MarketItem({
    required this.name,
    this.quantity = 1.0,
    this.unit = '',
    this.unitPrice = 0.0,
    this.isBought = false,
  });

  double get total => quantity * unitPrice;
}

@HiveType(typeId: 11)
class MarketList extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime createdAt;

  @HiveField(2)
  HiveList<MarketItem>? items;

  MarketList({
    required this.title,
    required this.createdAt,
    this.items,
  });
}
