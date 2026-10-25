import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/device_key_sync.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/data/fake/fake_device_key_repository.dart';
import 'package:money_scribe/features/auth/domain/device_key.dart';

/// The sign-in key of the phone that counts how often it was compared.
class _CountingDeviceKeys extends FakeDeviceKeyRepository {
  new({required super.demo, required super.auth});

  int syncs = 0;
  Exception? failure;

  @override
  Future<void> sync() async {
    syncs++;
    final failure = this.failure;
    if (failure != null) throw failure;
    await super.sync();
  }
}

void main() {
  late DemoController demo;

  setUp(() => demo = DemoController(latency: Duration.zero));

  DeviceKeySync watch(FakeAuthRepository auth, _CountingDeviceKeys keys) {
    final sync = DeviceKeySync(auth: auth, deviceKeys: keys);
    addTearDown(sync.dispose);
    return sync;
  }

  test('a person signing in has the key compared with the server', () async {
    final auth = FakeAuthRepository(demo: demo);
    final keys = _CountingDeviceKeys(demo: demo, auth: auth);
    watch(auth, keys);

    await auth.signIn(email: 'alex@example.com', password: 'p');
    await pumpEventQueue();

    expect(keys.syncs, 1);
  });

  test('an app that starts signed in compares it once at start', () async {
    final auth = FakeAuthRepository(demo: demo, signedIn: true);
    final keys = _CountingDeviceKeys(demo: demo, auth: auth);
    watch(auth, keys);
    await pumpEventQueue();

    expect(keys.syncs, 1);
  });

  test('signing out compares nothing', () async {
    final auth = FakeAuthRepository(demo: demo, signedIn: true);
    final keys = _CountingDeviceKeys(demo: demo, auth: auth);
    watch(auth, keys);
    await pumpEventQueue();

    await auth.signOut();
    await pumpEventQueue();

    expect(keys.syncs, 1);
  });

  test('a comparison that fails does not stop the next one', () async {
    final auth = FakeAuthRepository(demo: demo);
    final keys = _CountingDeviceKeys(demo: demo, auth: auth)
      ..failure = const NoConnectionException();
    watch(auth, keys);

    await auth.signIn(email: 'alex@example.com', password: 'p');
    await pumpEventQueue();
    await auth.signOut();
    await auth.signIn(email: 'alex@example.com', password: 'p');
    await pumpEventQueue();

    expect(keys.syncs, 2);
  });

  test('a key of another account is let go of after the sign-in', () async {
    final auth = FakeAuthRepository(demo: demo, signedIn: true);
    final keys = _CountingDeviceKeys(demo: demo, auth: auth);
    await keys.enable(password: 'p', prompt: 'Confirm');
    await auth.signOut();
    watch(auth, keys);

    await auth.signIn(email: 'sam@example.com', password: 'p');
    await pumpEventQueue();

    expect(await keys.signInAccount(), isNull);
    expect(await keys.support(), DeviceKeySupport.available);
  });
}
