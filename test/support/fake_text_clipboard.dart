import 'package:money_scribe/core/clipboard/text_clipboard.dart';

/// A clipboard that records what was copied.
class FakeTextClipboard implements TextClipboard {
  new();

  final List<String> copied = [];

  @override
  Future<void> copy(String text) async => copied.add(text);
}
