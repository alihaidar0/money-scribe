import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/push_token_cleanup.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/notifications/data/unavailable_push_messaging_repository.dart';

import '../support/fake_push_messaging_repository.dart';

void main() {
  late DemoController demo;
  late FakePushMessagingRepository push;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    push = FakePushMessagingRepository();
  });

  PushTokenCleanup watch(FakeAuthRepository auth) {
    final cleanup = PushTokenCleanup(auth: auth, push: push);
    addTearDown(cleanup.dispose);
    return cleanup;
  }

  test('signing out deletes the push token', () async {
    final auth = FakeAuthRepository(demo: demo, signedIn: true);
    watch(auth);

    await auth.signOut();
    await pumpEventQueue();

    expect(push.forgotten, 1);
  });

  test('deleting the account deletes the push token', () async {
    final auth = FakeAuthRepository(demo: demo, signedIn: true);
    watch(auth);

    await auth.deleteAccount(password: 'secret');
    await pumpEventQueue();

    expect(push.forgotten, 1);
  });

  test(
    'a password reset ends the session and deletes the push token',
    () async {
      final auth = FakeAuthRepository(demo: demo, signedIn: true);
      watch(auth);

      await auth.resetPassword('a long pass phrase');
      await pumpEventQueue();

      expect(push.forgotten, 1);
    },
  );

  test('being signed in, or starting signed out, deletes nothing', () async {
    final auth = FakeAuthRepository(demo: demo);
    watch(auth);

    await auth.signIn(email: 'alex@example.com', password: 'secret');
    await pumpEventQueue();

    expect(push.forgotten, 0);
  });

  test(
    'a token that cannot be deleted does not stop the next sign-out',
    () async {
      push = FakePushMessagingRepository(
        error: Exception('no Google services'),
      );
      final auth = FakeAuthRepository(demo: demo, signedIn: true);
      watch(auth);

      await auth.signOut();
      await pumpEventQueue();
      await auth.signIn(email: 'alex@example.com', password: 'secret');
      await auth.signOut();
      await pumpEventQueue();

      expect(push.forgotten, 2);
    },
  );

  test('stops listening once disposed', () async {
    final auth = FakeAuthRepository(demo: demo, signedIn: true);
    final cleanup = watch(auth);

    await cleanup.dispose();
    await auth.signOut();
    await pumpEventQueue();

    expect(push.forgotten, 0);
  });

  test('where push is unavailable there is nothing to delete', () async {
    final auth = FakeAuthRepository(demo: demo, signedIn: true);
    final cleanup = PushTokenCleanup(
      auth: auth,
      push: const UnavailablePushMessagingRepository(),
    );
    addTearDown(cleanup.dispose);

    await auth.signOut();

    await expectLater(pumpEventQueue(), completes);
  });
}
