import 'dart:typed_data';

/// A file the person picked: its name and what it holds.
typedef PickedFile = ({String name, Uint8List bytes});

/// The system file picker, for a `.csv` or a `.zip` file.
abstract interface class CsvFilePicker {
  /// `null` when the person chose nothing. Throws `CsvFileException` with
  /// `CsvFileIssue.tooLarge` for a file larger than [maxBytes], before it is
  /// read.
  Future<PickedFile?> pick({required int maxBytes});
}

/// The system share sheet, for an exported file.
abstract interface class CsvFileSharer {
  /// Saves [bytes] as [fileName] in the app's private cache and offers it to
  /// the other apps. The file of the export before is deleted first.
  Future<void> share(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
  });
}
