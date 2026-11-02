import 'package:uuid/uuid.dart';

class Asset {
  final String id;
  final String name;
  final double amount;
  final DateTime lastModified;

  Asset({
    required this.id,
    required this.name,
    required this.amount,
    required this.lastModified,
  });

  factory Asset.create({
    required String name,
    required double amount,
  }) {
    return Asset(
      id: const Uuid().v4(),
      name: name,
      amount: amount,
      lastModified: DateTime.now(),
    );
  }

  Asset copyWith({
    String? name,
    double? amount,
    DateTime? lastModified,
  }) {
    return Asset(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory Asset.fromMap(Map<dynamic, dynamic> map) {
    return Asset(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      lastModified: DateTime.parse(map['lastModified'] as String),
    );
  }
}
