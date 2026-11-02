import '../../data/models/asset.dart';

abstract class AssetRepository {
  List<Asset> getAssets();
  Future<void> addAsset(Asset asset);
  Future<void> updateAsset(Asset asset);
  Future<void> deleteAsset(String id);
}
