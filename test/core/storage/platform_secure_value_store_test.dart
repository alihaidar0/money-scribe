import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/storage/secure_value_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('keeps a value, reads it back and deletes it', () async {
    const store = PlatformSecureValueStore();

    expect(await store.read('key'), isNull);

    await store.write('key', 'value');
    expect(await store.read('key'), 'value');

    await store.delete('key');
    expect(await store.read('key'), isNull);
  });

  test('keeps each key apart', () async {
    const store = PlatformSecureValueStore();

    await store.write('one', '1');
    await store.write('two', '2');

    expect(await store.read('one'), '1');
    expect(await store.read('two'), '2');
  });

  test('reads a value it cannot decrypt as no value', () async {
    final store = PlatformSecureValueStore(_BrokenStorage());

    expect(await store.read('key'), isNull);
  });
}

/// A storage whose reads fail, as after a backup restored onto another device.
class _BrokenStorage implements FlutterSecureStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #read) {
      throw Exception('Failed to unwrap key');
    }
    return super.noSuchMethod(invocation);
  }
}
