import 'package:file_selector/file_selector.dart';
import 'package:money_scribe/features/settings/data/csv/csv_device.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';

/// The system file picker, through the official `file_selector` plugin. It
/// offers `.csv` and `.zip` files, under the names other apps give them.
class FileSelectorCsvPicker implements CsvFilePicker {
  const new();

  static const _types = XTypeGroup(
    label: 'CSV',
    extensions: ['csv', 'zip'],
    mimeTypes: [
      'text/csv',
      'text/comma-separated-values',
      'application/csv',
      'application/vnd.ms-excel',
      'application/zip',
      'application/x-zip-compressed',
    ],
    uniformTypeIdentifiers: [
      'public.comma-separated-values-text',
      'public.zip-archive',
    ],
  );

  @override
  Future<PickedFile?> pick({required int maxBytes}) async {
    final file = await openFile(acceptedTypeGroups: const [_types]);
    if (file == null) return null;
    if (await file.length() > maxBytes) {
      throw const CsvFileException(CsvFileIssue.tooLarge);
    }
    return (name: file.name, bytes: await file.readAsBytes());
  }
}
