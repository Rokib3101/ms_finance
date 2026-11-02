import 'package:hive/hive.dart';
import '../../domain/repositories/asset_repository.dart';
import '../models/asset.dart';

class HiveAssetRepository implements AssetRepository {
  Box get _assetBox => Hive.box('assets');

  @override
  List<Asset> getAssets() {
    return _assetBox.values.map((e) => Asset.fromMap(e as Map)).toList();
  }

  @override
  Future<void> addAsset(Asset asset) async {
    await _assetBox.put(asset.id, asset.toMap());
  }

  @override
  Future<void> updateAsset(Asset asset) async {
    await _assetBox.put(asset.id, asset.toMap());
  }

  @override
  Future<void> deleteAsset(String id) async {
    await _assetBox.delete(id);
  }
}
