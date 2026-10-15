import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/clipboard/system_text_clipboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('copies the text to the system clipboard', () async {
    final copied = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await const SystemTextClipboard().copy('hello');

    expect(copied, ['hello']);
  });
}
