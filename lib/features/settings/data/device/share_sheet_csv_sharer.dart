import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:money_scribe/features/settings/data/csv/csv_device.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// The system share sheet, through `share_plus`. On a phone the file is
/// written to a folder of the app's private cache, which nothing else can
/// read; it stays there only until the next export or the next start of the
/// app, because the app the person shares with may still be reading it when
/// the share sheet closes. On the web it is handed over from memory.
class ShareSheetCsvSharer implements CsvFileSharer {
  const new();

  static const _folder = 'exports';

  @override
  Future<void> share(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
  }) async {
    if (kIsWeb) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, name: fileName, mimeType: mimeType)],
        ),
      );
      return;
    }
    final folder = await _exports();
    await deleteLeftovers();
    await folder.create(recursive: true);
    final file = File('${folder.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: mimeType)]),
    );
  }

  /// Deletes the files of earlier exports. Call it when the app starts.
  Future<void> deleteLeftovers() async {
    if (kIsWeb) return;
    final folder = await _exports();
    if (folder.existsSync()) await folder.delete(recursive: true);
  }

  static Future<Directory> _exports() async {
    final cache = await getTemporaryDirectory();
    return Directory('${cache.path}/$_folder');
  }
}
