import 'package:flutter/material.dart';
import '../../data/models/asset.dart';
import '../../domain/repositories/asset_repository.dart';
import '../../data/repositories/hive_asset_repository.dart';

class AssetProvider extends ChangeNotifier {
  final AssetRepository _repository;
  List<Asset> _assets = [];

  List<Asset> get assets => _assets;

  AssetProvider({AssetRepository? repository})
      : _repository = repository ?? HiveAssetRepository() {
    loadAssets();
  }

  void loadAssets() {
    _assets = _repository.getAssets();
    notifyListeners();
  }

  double get totalAssetValue =>
      _assets.fold(0, (sum, item) => sum + item.amount);

  Future<String> addAsset(String name, double amount) async {
    final newAsset = Asset.create(name: name, amount: amount);
    await _repository.addAsset(newAsset);
    _assets.add(newAsset);
    notifyListeners();
    return newAsset.id;
  }

  Future<void> updateAsset(String id, {String? name, double? amount}) async {
    final index = _assets.indexWhere((element) => element.id == id);
    if (index != -1) {
      final updatedAsset = _assets[index].copyWith(
        name: name,
        amount: amount,
        lastModified: DateTime.now(),
      );
      await _repository.updateAsset(updatedAsset);
      _assets[index] = updatedAsset;
      notifyListeners();
    }
  }

  Future<void> deleteAsset(String id) async {
    await _repository.deleteAsset(id);
    _assets.removeWhere((element) => element.id == id);
    notifyListeners();
  }
}
