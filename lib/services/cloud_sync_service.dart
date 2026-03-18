import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:carbon_tracker/services/database_service.dart';

/// Handles data export/import for user-controlled cloud sync.
///
/// Philosophy: Your data, your cloud.
/// We don't run any servers. Instead, users export their data as a JSON file
/// and save it to their own Google Drive, OneDrive, iCloud, or wherever they
/// choose. This keeps the app truly free and private.
class CloudSyncService {
  final DatabaseService _db;

  CloudSyncService(this._db);

  /// Export all data to a JSON file and let the user save/share it.
  /// The user can then upload this to their own cloud storage.
  Future<String?> exportData() async {
    try {
      final jsonData = await _db.exportToJson();
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().split('T').first;
      final file = File('${dir.path}/voetje_backup_$timestamp.json');
      await file.writeAsString(jsonData);
      return file.path;
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    }
  }

  /// Share the export file using the system share sheet.
  /// Users can pick Google Drive, OneDrive, email, etc.
  Future<void> shareExport() async {
    final filePath = await exportData();
    if (filePath != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'Voetje Backup',
          text: 'My Voetje data backup',
        ),
      );
    }
  }

  /// Import data from a JSON file the user selects.
  /// Returns the number of entries imported, or -1 on error.
  Future<int> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return 0;

      final file = result.files.first;
      String jsonString;

      if (file.bytes != null) {
        jsonString = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        jsonString = await File(file.path!).readAsString();
      } else {
        return -1;
      }

      // Validate JSON structure
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      if (!data.containsKey('entries')) {
        return -1;
      }

      return await _db.importFromJson(jsonString);
    } catch (e) {
      debugPrint('Import error: $e');
      return -1;
    }
  }

  /// Get a summary of the current data for display
  Future<Map<String, dynamic>> getDataSummary() async {
    final count = await _db.getEntryCount();
    final jsonData = await _db.exportToJson();
    final sizeBytes = utf8.encode(jsonData).length;

    return {
      'entryCount': count,
      'sizeKB': (sizeBytes / 1024).toStringAsFixed(1),
    };
  }
}
