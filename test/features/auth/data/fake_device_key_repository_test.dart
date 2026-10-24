import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/data/fake/fake_device_key_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/device_key.dart';

void main() {
  late DemoController demo;
  late FakeAuthRepository auth;
  late FakeDeviceKeyRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    auth = FakeAuthRepository(demo: demo, signedIn: true);
    repository = FakeDeviceKeyRepository(
      demo: demo,
      auth: auth,
      now: () => DateTime(2026, 10, 24),
    );
  });

  Future<void> enable() => repository.enable(password: 'p', prompt: 'Confirm');

  test('is off at first, with nobody to sign in', () async {
    expect(await repository.isEnabled(), isFalse);
    expect(await repository.signInAccount(), isNull);
    expect(await repository.support(), DeviceKeySupport.available);
  });

  test('turning it on keeps the account with its email hidden', () async {
    await enable();

    expect(await repository.isEnabled(), isTrue);
    expect(
      await repository.signInAccount(),
      FingerprintAccount(
        accountId: auth.accountId!,
        name: 'Alex',
        maskedEmail: 'a***@example.com',
      ),
    );
  });

  test('turning it off forgets the account', () async {
    await enable();

    await repository.disable();

    expect(await repository.isEnabled(), isFalse);
    expect(await repository.signInAccount(), isNull);
  });

  test('signs in as the account when the person is signed out', () async {
    await enable();
    await auth.signOut();
    expect(auth.isSignedIn, isFalse);

    await repository.signIn(prompt: 'Sign in');

    expect(auth.isSignedIn, isTrue);
  });

  test('without the sign-in on, it is refused', () async {
    await expectLater(
      repository.signIn(prompt: 'Sign in'),
      throwsA(isA<FingerprintRefusedException>()),
    );
  });

  test('a different account does not inherit it', () async {
    await enable();
    await auth.signOut();
    await auth.signIn(email: 'sam@example.com', password: 'p');

    await repository.sync();

    expect(await repository.isEnabled(), isFalse);
    expect(await repository.signInAccount(), isNull);
  });

  group('the demo panel', () {
    Future<Object?> failure(Future<void> Function() action) async {
      try {
        await action();
      } on Object catch (error) {
        return error;
      }
      return null;
    }

    test('a wrong password refuses turning it on', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));

      expect(await failure(enable), isA<WrongCredentialsException>());
      expect(await repository.isEnabled(), isFalse);
    });

    test('a phone without a fingerprint cannot turn it on', () async {
      demo.update(const DemoSettings(fingerprint: DemoFingerprint.notEnrolled));

      expect(await repository.support(), DeviceKeySupport.notEnrolled);
      expect(await failure(enable), isA<FingerprintUnavailableException>());
    });

    test('a fingerprint that does not match signs nobody in', () async {
      await enable();
      await auth.signOut();
      demo.update(const DemoSettings(fingerprint: DemoFingerprint.notMatched));

      expect(
        await failure(() => repository.signIn(prompt: 'Sign in')),
        isA<FingerprintCancelledException>(),
      );
      expect(auth.isSignedIn, isFalse);
    });

    test('a refused sign-in leaves the key', () async {
      await enable();
      await auth.signOut();
      demo.update(
        const DemoSettings(fingerprint: DemoFingerprint.signInRefused),
      );

      expect(
        await failure(() => repository.signIn(prompt: 'Sign in')),
        isA<FingerprintRefusedException>(),
      );
      expect(await repository.signInAccount(), isNotNull);
    });

    test('a locked sign-in is a wait', () async {
      await enable();
      await auth.signOut();
      demo.update(const DemoSettings(fingerprint: DemoFingerprint.locked));

      expect(
        await failure(() => repository.signIn(prompt: 'Sign in')),
        isA<RateLimitedException>().having(
          (e) => e.reason,
          'reason',
          RateLimitReason.signInLocked,
        ),
      );
    });
  });

  group('the phones', () {
    test('lists the others, and this phone once the sign-in is on', () async {
      expect((await repository.keys()).map((entry) => entry.isCurrent), [
        false,
        false,
      ]);

      await enable();

      final keys = await repository.keys();
      expect(keys.first.isCurrent, isTrue);
      expect(keys, hasLength(3));
    });

    test('removing another phone leaves this one', () async {
      await enable();

      await repository.removeKey('fake-other-ios');

      expect((await repository.keys()).map((entry) => entry.deviceId), [
        FakeDeviceKeyRepository.thisDeviceId,
        'fake-other-android',
      ]);
      expect(await repository.isEnabled(), isTrue);
    });

    test('removing this phone turns the sign-in off', () async {
      await enable();

      await repository.removeKey(FakeDeviceKeyRepository.thisDeviceId);

      expect(await repository.isEnabled(), isFalse);
    });
  });
}
