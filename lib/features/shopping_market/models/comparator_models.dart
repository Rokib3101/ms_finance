// HiveList is used to preserve the current on-disk relationship schema.
// ignore_for_file: experimental_member_use

import 'package:hive/hive.dart';

part 'comparator_models.g.dart';

@HiveType(typeId: 12)
class ComparatorItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double quantity;

  @HiveField(2)
  String unit;

  @HiveField(3)
  double totalPrice;

  ComparatorItem({
    required this.name,
    this.quantity = 0.0,
    this.unit = '',
    this.totalPrice = 0.0,
  });

  double get unitPrice => quantity > 0 ? totalPrice / quantity : 0.0;
}

@HiveType(typeId: 13)
class ComparatorList extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime createdAt;

  @HiveField(2)
  HiveList<ComparatorItem>? items;

  ComparatorList({
    required this.title,
    required this.createdAt,
    this.items,
  });
}
