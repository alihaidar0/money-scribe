import 'package:flutter/services.dart';
import 'package:money_scribe/core/clipboard/text_clipboard.dart';

/// The clipboard of the device.
class SystemTextClipboard implements TextClipboard {
  const new();

  @override
  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
