import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/notifications/data/push_messaging_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('push is unavailable outside Android', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final repository = await createPushMessagingRepository();

    expect(repository.isAvailable, isFalse);
  });

  test('push is unavailable when Firebase cannot start, and the app still '
      'starts', () async {
    // Android, but there is no Firebase configuration in a unit test.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final repository = await createPushMessagingRepository();

    expect(repository.isAvailable, isFalse);
  });
}
