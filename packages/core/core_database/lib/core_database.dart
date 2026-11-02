library core_database;

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalPersistence {
  static late HiveAesCipher financeCipher;
  static bool isInitialized = false;

  static Future<void> init() async {
    if (isInitialized) return;
    await Hive.initFlutter();

    const secureStorage = FlutterSecureStorage();
    String? keyString =
        await secureStorage.read(key: 'ms_smart_tools_finance_key');

    List<int> key;
    if (keyString == null) {
      key = Hive.generateSecureKey();
      await secureStorage.write(
        key: 'ms_smart_tools_finance_key',
        value: base64UrlEncode(key),
      );
    } else {
      key = base64Url.decode(keyString);
    }

    financeCipher = HiveAesCipher(key);
    isInitialized = true;
  }

  static Future<Box<T>> openEncryptedBox<T>(String boxName) async {
    if (!isInitialized) {
      await init();
    }
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }

    // 1. First, attempt to open the box as an encrypted box.
    // This is the normal path for encrypted boxes (created, updated, or restored).
    try {
      return await Hive.openBox<T>(
        boxName,
        encryptionCipher: financeCipher,
      );
    } catch (_) {
      // Opening with financeCipher failed. This indicates the box on disk
      // is a legacy unencrypted box from an older version that needs migration.
    }

    // 2. Handle legacy migration (unencrypted box -> encrypted box).
    final stagingName = '${boxName}_encrypted_migration_v1';
    final stagingExists = await Hive.boxExists(stagingName);

    if (stagingExists) {
      try {
        final staged = await Hive.openBox<T>(
          stagingName,
          encryptionCipher: financeCipher,
        );
        final stagedValues = <dynamic, T>{
          for (final key in staged.keys) key: staged.get(key) as T,
        };
        await staged.close();
        if (await Hive.boxExists(boxName)) {
          await Hive.deleteBoxFromDisk(boxName);
        }
        final encrypted = await Hive.openBox<T>(
          boxName,
          encryptionCipher: financeCipher,
        );
        await encrypted.putAll(stagedValues);
        await Hive.deleteBoxFromDisk(stagingName);
        return encrypted;
      } catch (_) {
        await Hive.deleteBoxFromDisk(stagingName);
      }
    }

    Map<dynamic, T> legacyValues = {};
    if (await Hive.boxExists(boxName)) {
      try {
        final legacy = await Hive.openBox<T>(boxName);
        legacyValues = <dynamic, T>{
          for (final key in legacy.keys) key: legacy.get(key) as T,
        };
        await legacy.close();
      } catch (_) {
        await Hive.deleteBoxFromDisk(boxName);
        return Hive.openBox<T>(
          boxName,
          encryptionCipher: financeCipher,
        );
      }
    }

    try {
      final staged = await Hive.openBox<T>(
        stagingName,
        encryptionCipher: financeCipher,
      );
      await staged.putAll(legacyValues);
      await staged.close();

      await Hive.deleteBoxFromDisk(boxName);

      final encrypted = await Hive.openBox<T>(
        boxName,
        encryptionCipher: financeCipher,
      );
      await encrypted.putAll(legacyValues);
      await Hive.deleteBoxFromDisk(stagingName);
      return encrypted;
    } catch (_) {
      await Hive.deleteBoxFromDisk(stagingName);
      if (await Hive.boxExists(boxName)) {
        await Hive.deleteBoxFromDisk(boxName);
      }
      return Hive.openBox<T>(
        boxName,
        encryptionCipher: financeCipher,
      );
    }
  }
}
