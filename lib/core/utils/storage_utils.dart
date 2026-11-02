import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class StorageUtils {
  static Future<String> getAppOutputDir() async {
    if (Platform.isAndroid) {
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final customPath = '${extDir.path}/MS Finance';
          final dir = Directory(customPath);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          return customPath;
        }
      } catch (_) {}

      final docDir = await getApplicationDocumentsDirectory();
      final customPath = '${docDir.path}/MS Finance';
      final dir = Directory(customPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return customPath;
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      final customPath = '${docDir.path}/MS Finance';
      final dir = Directory(customPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return customPath;
    }
  }

  static Future<String?> saveFileToCustomFolder(
    String sourcePath,
    String fileName,
  ) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;

      try {
        final outputDir = await getAppOutputDir();
        final targetPath = '$outputDir/$fileName';
        await sourceFile.copy(targetPath);
        final targetFile = File(targetPath);
        if (await targetFile.exists() && await targetFile.length() > 0) {
          return targetPath;
        }
      } catch (e) {
        debugPrint('Copy file error: $e');
      }

      return sourcePath;
    } catch (e) {
      debugPrint('Save error: $e');
    }
    return null;
  }

  static Future<String?> saveDocumentToStorage({
    required String sourcePath,
    required String fileName,
  }) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;
      final bytes = await sourceFile.readAsBytes();

      if (bytes.isEmpty) {
        debugPrint('Source file bytes are empty!');
        return null;
      }

      final ext = fileName.contains('.') ? fileName.split('.').last : '';
      Uri? savedUri;

      try {
        savedUri = await FilePicker.saveFile(
          dialogTitle: 'স্টোরেজে সেভ করুন',
          fileName: fileName,
          type: ext.isNotEmpty ? FileType.custom : FileType.any,
          allowedExtensions: ext.isNotEmpty ? [ext] : null,
          bytes: bytes,
        );
      } catch (e) {
        debugPrint('FilePicker saveFile error: $e');
      }

      if (savedUri != null) {
        // File Picker's save API writes [bytes] itself and may return a
        // content:// URI on Android instead of a filesystem path.
        return savedUri.toString();
      }

      // Fallback to custom app directory if FilePicker failed or created a 0 KB file
      return await saveFileToCustomFolder(sourcePath, fileName);
    } catch (e) {
      debugPrint('saveDocumentToStorage error: $e');
      return await saveFileToCustomFolder(sourcePath, fileName);
    }
  }
}
