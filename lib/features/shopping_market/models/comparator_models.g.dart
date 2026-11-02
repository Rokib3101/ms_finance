// ignore_for_file: experimental_member_use

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comparator_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ComparatorItemAdapter extends TypeAdapter<ComparatorItem> {
  @override
  final int typeId = 12;

  @override
  ComparatorItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ComparatorItem(
      name: fields[0] as String,
      quantity: fields[1] as double,
      unit: fields[2] as String,
      totalPrice: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ComparatorItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.totalPrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComparatorItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ComparatorListAdapter extends TypeAdapter<ComparatorList> {
  @override
  final int typeId = 13;

  @override
  ComparatorList read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ComparatorList(
      title: fields[0] as String,
      createdAt: fields[1] as DateTime,
      items: (fields[2] as HiveList?)?.castHiveList(),
    );
  }

  @override
  void write(BinaryWriter writer, ComparatorList obj) {
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
      other is ComparatorListAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
