import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

void main() {
  late DemoController demo;
  late DateTime now;
  late FakeAuthRepository auth;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    now = DateTime(2026, 10, 11, 9);
    auth = FakeAuthRepository(demo: demo, now: () => now);
  });

  Future<void> signIn() => auth.signIn(email: 'a@b.c', password: 'x');

  group('sign in', () {
    test('starts signed out', () => expect(auth.isSignedIn, isFalse));

    test('accepts any email and password', () async {
      await signIn();

      expect(auth.isSignedIn, isTrue);
    });

    test('tells listeners when the person signs in and out', () async {
      final changes = <bool>[];
      auth.signedInChanges.listen(changes.add);

      await signIn();
      await auth.signOut();

      expect(changes, [true, false]);
    });

    test('refuses a wrong password', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));

      await expectLater(signIn(), throwsA(isA<WrongCredentialsException>()));
      expect(auth.isSignedIn, isFalse);
    });

    test('locks for five minutes after five wrong passwords', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));
      for (var attempt = 1; attempt < 5; attempt++) {
        await expectLater(signIn(), throwsA(isA<WrongCredentialsException>()));
      }

      await expectLater(
        signIn(),
        throwsA(
          isA<TooManyAttemptsException>().having(
            (error) => error.retryAfter,
            'retryAfter',
            const Duration(minutes: 5),
          ),
        ),
      );
      expect(auth.signInLockRemaining, const Duration(minutes: 5));
    });

    test('the lock counts down and ends', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.locked));
      await expectLater(signIn(), throwsA(isA<TooManyAttemptsException>()));

      now = now.add(const Duration(minutes: 2));
      expect(auth.signInLockRemaining, const Duration(minutes: 3));

      now = now.add(const Duration(minutes: 3));
      expect(auth.signInLockRemaining, isNull);
    });

    test('a new demo outcome clears the lock', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.locked));
      await expectLater(signIn(), throwsA(isA<TooManyAttemptsException>()));

      demo.update(const DemoSettings());

      expect(auth.signInLockRemaining, isNull);
      await signIn();
      expect(auth.isSignedIn, isTrue);
    });

    test('fails like the demo server does', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));

      await expectLater(signIn(), throwsA(isA<NoConnectionException>()));
    });
  });

  group('register', () {
    test('accepts any data and remembers the email for the code', () async {
      await auth.register(name: 'Alex', email: 'new@b.c', password: 'x');

      expect(auth.pendingEmail, 'new@b.c');
      expect(auth.isSignedIn, isFalse);
    });

    test('a new account has no data yet', () async {
      await auth.register(name: 'Alex', email: 'new@b.c', password: 'x');

      expect(demo.settings.scenario, DemoScenario.empty);
    });

    test('signing in to an existing account brings its data', () async {
      await auth.register(name: 'Alex', email: 'new@b.c', password: 'x');

      await signIn();

      expect(demo.settings.scenario, DemoScenario.normal);
    });

    test('signing in leaves a forced error or slow answer alone', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.loading));

      await signIn();

      expect(demo.settings.scenario, DemoScenario.loading);
    });

    test('can refuse the data, all the ways at once', () async {
      demo.update(const DemoSettings(registration: DemoRegistration.rejected));

      await expectLater(
        auth.register(name: 'Alex', email: 'new@b.c', password: 'x'),
        throwsA(
          isA<RegistrationRejectedException>().having(
            (error) => error.problems,
            'problems',
            RegistrationProblem.values.toSet(),
          ),
        ),
      );
    });
  });

  group('codes', () {
    test('any code verifies the email and signs the person in', () async {
      await auth.verifyCode(CodePurpose.verifyEmail, '1234');

      expect(auth.isSignedIn, isTrue);
    });

    test('any code resets the password without signing in', () async {
      await auth.verifyCode(CodePurpose.resetPassword, '1234');

      expect(auth.isSignedIn, isFalse);
    });

    test('a wrong code counts the tries down, then expires', () async {
      demo.update(const DemoSettings(code: DemoCode.wrong));
      Future<void> verify() => auth.verifyCode(CodePurpose.verifyEmail, '1');

      await expectLater(
        verify(),
        throwsA(
          isA<WrongCodeException>().having((e) => e.attemptsLeft, 'left', 2),
        ),
      );
      await expectLater(
        verify(),
        throwsA(
          isA<WrongCodeException>().having((e) => e.attemptsLeft, 'left', 1),
        ),
      );
      await expectLater(verify(), throwsA(isA<CodeExpiredException>()));
    });

    test('a new code starts the tries again', () async {
      demo.update(const DemoSettings(code: DemoCode.wrong));
      await expectLater(
        auth.verifyCode(CodePurpose.verifyEmail, '1'),
        throwsA(isA<WrongCodeException>()),
      );

      await auth.resendCode(CodePurpose.verifyEmail);

      await expectLater(
        auth.verifyCode(CodePurpose.verifyEmail, '1'),
        throwsA(
          isA<WrongCodeException>().having((e) => e.attemptsLeft, 'left', 2),
        ),
      );
    });

    test('an expired code stays expired', () async {
      demo.update(const DemoSettings(code: DemoCode.expired));

      await expectLater(
        auth.verifyCode(CodePurpose.verifyEmail, '1234'),
        throwsA(isA<CodeExpiredException>()),
      );
    });
  });
}
