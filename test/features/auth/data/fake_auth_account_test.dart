import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/account_profile.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/password_problem.dart';

void main() {
  late DemoController demo;
  late FakeAuthRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeAuthRepository(demo: demo, signedIn: true);
  });

  group('profile', () {
    test('is the sample account', () async {
      final profile = await repository.profile();

      expect(profile.name, 'Alex');
      expect(profile.email, 'alex@example.com');
    });

    test('is the account that was registered', () async {
      await repository.register(
        name: '  Dana ',
        email: 'dana@example.com',
        password: 'a-password-1',
      );

      final profile = await repository.profile();

      expect(profile.name, 'Dana');
      expect(profile.email, 'dana@example.com');
    });

    test('signing in as another address gives a name made from it', () async {
      await repository.signOut();
      await repository.signIn(email: 'whoever@example.com', password: 'x');

      final profile = await repository.profile();

      expect(profile.name, 'Whoever');
      expect(profile.email, 'whoever@example.com');
    });

    test('signing in as the sample account keeps its name', () async {
      await repository.signOut();
      await repository.signIn(email: 'ALEX@example.com', password: 'x');

      expect((await repository.profile()).name, 'Alex');
    });

    test('fails like the server does', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));

      await expectLater(
        repository.profile(),
        throwsA(isA<NoConnectionException>()),
      );
    });

    test('the initial is the first letter, in capitals', () {
      expect(const AccountProfile(name: 'alex', email: 'a@b.c').initial, 'A');
      expect(const AccountProfile(name: ' ', email: 'a@b.c').initial, '?');
    });
  });

  group('change password', () {
    test('is accepted', () async {
      await repository.changePassword(current: 'old', next: 'new-password-1');
    });

    test('refuses a wrong current password', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));

      await expectLater(
        repository.changePassword(current: 'old', next: 'new-password-1'),
        throwsA(isA<WrongCredentialsException>()),
      );
    });

    test('refuses a new password that is the current one', () async {
      await expectLater(
        repository.changePassword(current: 'same', next: 'same'),
        throwsA(
          isA<PasswordRejectedException>().having(
            (e) => e.problem.issue,
            'issue',
            PasswordIssue.unchanged,
          ),
        ),
      );
    });

    test('says what the demo panel asks for', () async {
      demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.locked),
      );
      await expectLater(
        repository.changePassword(current: 'old', next: 'new-password-1'),
        throwsA(
          isA<RateLimitedException>()
              .having(
                (e) => e.reason,
                'reason',
                RateLimitReason.passwordAttemptsExceeded,
              )
              .having(
                (e) => e.retryAfter,
                'retryAfter',
                const Duration(minutes: 15),
              ),
        ),
      );

      demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.unavailable),
      );
      await expectLater(
        repository.changePassword(current: 'old', next: 'new-password-1'),
        throwsA(isA<ServiceUnavailableException>()),
      );

      demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.passwordRefused),
      );
      await expectLater(
        repository.changePassword(current: 'old', next: 'new-password-1'),
        throwsA(isA<PasswordRejectedException>()),
      );
    });

    test('keeps the person signed in', () async {
      await repository.changePassword(current: 'old', next: 'new-password-1');

      expect(repository.isSignedIn, isTrue);
    });
  });

  group('delete account', () {
    test('signs the person out', () async {
      final changes = <bool>[];
      final subscription = repository.signedInChanges.listen(changes.add);
      addTearDown(subscription.cancel);

      await repository.deleteAccount(password: 'secret');

      expect(repository.isSignedIn, isFalse);
      expect(changes, [false]);
    });

    test(
      'shares the lock and the busy server with changing the password',
      () async {
        demo.update(
          const DemoSettings(passwordChange: DemoPasswordChange.locked),
        );
        await expectLater(
          repository.deleteAccount(password: 'secret'),
          throwsA(
            isA<RateLimitedException>().having(
              (e) => e.reason,
              'reason',
              RateLimitReason.passwordAttemptsExceeded,
            ),
          ),
        );

        demo.update(
          const DemoSettings(passwordChange: DemoPasswordChange.unavailable),
        );
        await expectLater(
          repository.deleteAccount(password: 'secret'),
          throwsA(isA<ServiceUnavailableException>()),
        );
        expect(repository.isSignedIn, isTrue);
      },
    );

    test('refuses a wrong password and stays signed in', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));

      await expectLater(
        repository.deleteAccount(password: 'nope'),
        throwsA(isA<WrongCredentialsException>()),
      );
      expect(repository.isSignedIn, isTrue);
    });
  });
}
