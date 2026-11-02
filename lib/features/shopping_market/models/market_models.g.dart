// ignore_for_file: experimental_member_use

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MarketItemAdapter extends TypeAdapter<MarketItem> {
  @override
  final int typeId = 10;

  @override
  MarketItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MarketItem(
      name: fields[0] as String,
      quantity: fields[1] as double,
      unit: fields[2] as String,
      unitPrice: fields[3] as double,
      isBought: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MarketItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.unitPrice)
      ..writeByte(4)
      ..write(obj.isBought);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MarketListAdapter extends TypeAdapter<MarketList> {
  @override
  final int typeId = 11;

  @override
  MarketList read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MarketList(
      title: fields[0] as String,
      createdAt: fields[1] as DateTime,
      items: (fields[2] as HiveList?)?.castHiveList(),
    );
  }

  @override
  void write(BinaryWriter writer, MarketList obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketListAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
