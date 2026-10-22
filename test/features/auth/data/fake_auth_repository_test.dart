import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/password_problem.dart';

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

  Future<void> register([String email = 'new@b.c']) {
    return auth.register(name: 'Alex', email: email, password: 'x');
  }

  Matcher rateLimited(RateLimitReason reason, Duration retryAfter) {
    return isA<RateLimitedException>()
        .having((error) => error.reason, 'reason', reason)
        .having((error) => error.retryAfter, 'retryAfter', retryAfter);
  }

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

      await expectLater(signIn(), throwsA(isA<WrongPasswordException>()));
      expect(auth.isSignedIn, isFalse);
    });

    test('asks for a challenge first, then signs in with its token', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.challengeRequired));

      await expectLater(signIn(), throwsA(isA<ChallengeRequiredException>()));
      expect(auth.isSignedIn, isFalse);

      await auth.signIn(email: 'a@b.c', password: 'x', challengeToken: 't');
      expect(auth.isSignedIn, isTrue);
    });

    test('refuses every token when the demo says so', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.challengeRejected));

      await expectLater(signIn(), throwsA(isA<ChallengeRequiredException>()));
      await expectLater(
        auth.signIn(email: 'a@b.c', password: 'x', challengeToken: 't'),
        throwsA(isA<ChallengeRejectedException>()),
      );
      expect(auth.isSignedIn, isFalse);
    });

    test('refuses an email without an account', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.emailNotRegistered));

      await expectLater(signIn(), throwsA(isA<EmailNotRegisteredException>()));
      expect(auth.isSignedIn, isFalse);
    });

    test('locks for five minutes after five wrong passwords', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));
      for (var attempt = 1; attempt < 5; attempt++) {
        await expectLater(signIn(), throwsA(isA<WrongPasswordException>()));
      }

      await expectLater(
        signIn(),
        throwsA(
          rateLimited(RateLimitReason.signInLocked, const Duration(minutes: 5)),
        ),
      );
      expect(auth.signInLockRemaining, const Duration(minutes: 5));
    });

    test('the lock counts down and ends', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.locked));
      await expectLater(signIn(), throwsA(isA<RateLimitedException>()));

      now = now.add(const Duration(minutes: 2));
      expect(auth.signInLockRemaining, const Duration(minutes: 3));

      now = now.add(const Duration(minutes: 3));
      expect(auth.signInLockRemaining, isNull);
    });

    test('a new demo outcome clears the lock', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.locked));
      await expectLater(signIn(), throwsA(isA<RateLimitedException>()));

      demo.update(const DemoSettings());

      expect(auth.signInLockRemaining, isNull);
      await signIn();
      expect(auth.isSignedIn, isTrue);
    });

    test('an address that is not verified opens the code step', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.emailNotVerified));

      await expectLater(
        auth.signIn(email: ' late@b.c ', password: 'x'),
        throwsA(isA<EmailNotVerifiedException>()),
      );

      expect(auth.isSignedIn, isFalse);
      expect(auth.pendingEmail, 'late@b.c');
      // Nothing was sent by the sign-in: a code can be asked for at once.
      expect(auth.resendWaitRemaining, Duration.zero);
    });

    test('a busy server asks to try again shortly', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.unavailable));

      await expectLater(signIn(), throwsA(isA<ServiceUnavailableException>()));
    });

    test('fails like the demo server does', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));

      await expectLater(signIn(), throwsA(isA<NoConnectionException>()));
    });
  });

  group('register', () {
    test('accepts any data and remembers the email for the code', () async {
      await register();

      expect(auth.pendingEmail, 'new@b.c');
      expect(auth.isSignedIn, isFalse);
    });

    test('starts the wait before a new code can be asked for', () async {
      await register();

      expect(auth.resendWaitRemaining, const Duration(seconds: 60));

      now = now.add(const Duration(seconds: 45));
      expect(auth.resendWaitRemaining, const Duration(seconds: 15));

      now = now.add(const Duration(seconds: 15));
      expect(auth.resendWaitRemaining, Duration.zero);
    });

    test('the same address again inside the wait is asked to wait', () async {
      await register();
      now = now.add(const Duration(seconds: 20));

      await expectLater(
        register(),
        throwsA(
          rateLimited(
            RateLimitReason.resendTooSoon,
            const Duration(seconds: 40),
          ),
        ),
      );
    });

    test('another address, or the same after the wait, is accepted', () async {
      await register();

      await register('other@b.c');
      expect(auth.pendingEmail, 'other@b.c');

      now = now.add(const Duration(seconds: 61));
      await register('other@b.c');
      expect(auth.resendWaitRemaining, const Duration(seconds: 60));
    });

    test('a new account has no data yet', () async {
      await register();

      expect(demo.settings.scenario, DemoScenario.empty);
    });

    test('signing in to an existing account brings its data', () async {
      await register();

      await signIn();

      expect(demo.settings.scenario, DemoScenario.normal);
    });

    test('signing in leaves a forced error or slow answer alone', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.loading));

      await signIn();

      expect(demo.settings.scenario, DemoScenario.loading);
    });

    test('can refuse the email and the password', () async {
      demo.update(const DemoSettings(registration: DemoRegistration.rejected));

      await expectLater(
        register(),
        throwsA(
          isA<RegistrationRejectedException>()
              .having(
                (error) => error.password,
                'password',
                const PasswordProblem(
                  PasswordIssue.tooShort,
                  limit: FakeAuthRepository.demoMinimumPasswordLength,
                ),
              )
              .having((error) => error.emailInvalid, 'emailInvalid', isTrue),
        ),
      );
    });

    test('can ask to wait, as if the address was just registered', () async {
      demo.update(const DemoSettings(registration: DemoRegistration.tooSoon));

      await expectLater(
        register(),
        throwsA(
          rateLimited(
            RateLimitReason.resendTooSoon,
            FakeAuthRepository.resendWait,
          ),
        ),
      );
    });

    test('a busy server asks to try again shortly', () async {
      demo.update(
        const DemoSettings(registration: DemoRegistration.unavailable),
      );

      await expectLater(
        register(),
        throwsA(isA<ServiceUnavailableException>()),
      );
    });
  });

  group('codes', () {
    test('any code verifies the email and signs the person in', () async {
      await auth.verifyCode(CodePurpose.verifyEmail, '123456');

      expect(auth.isSignedIn, isTrue);
    });

    test('any code resets the password without signing in', () async {
      await auth.verifyCode(CodePurpose.resetPassword, '123456');

      expect(auth.isSignedIn, isFalse);
    });

    test('a wrong code counts the tries down, then the code is dead', () async {
      demo.update(const DemoSettings(code: DemoCode.wrong));
      Future<void> verify() => auth.verifyCode(CodePurpose.verifyEmail, '1');

      for (final left in [4, 3, 2, 1]) {
        await expectLater(
          verify(),
          throwsA(
            isA<WrongCodeException>().having(
              (e) => e.attemptsLeft,
              'left',
              left,
            ),
          ),
        );
      }
      // The fifth wrong code kills it, and the server says how long until a
      // new one may be asked for.
      await expectLater(
        verify(),
        throwsA(
          rateLimited(
            RateLimitReason.codeAttemptsExceeded,
            FakeAuthRepository.resendWait,
          ),
        ),
      );
      expect(auth.resendWaitRemaining, FakeAuthRepository.resendWait);
      // A dead code stays dead: another try is a code that is no longer valid.
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
          isA<WrongCodeException>().having((e) => e.attemptsLeft, 'left', 4),
        ),
      );
    });

    test('an expired code stays expired', () async {
      demo.update(const DemoSettings(code: DemoCode.expired));

      await expectLater(
        auth.verifyCode(CodePurpose.verifyEmail, '123456'),
        throwsA(isA<CodeExpiredException>()),
      );
    });

    test('too many tries kills the code and starts the wait', () async {
      demo.update(const DemoSettings(code: DemoCode.attemptsExceeded));

      await expectLater(
        auth.verifyCode(CodePurpose.verifyEmail, '123456'),
        throwsA(
          rateLimited(
            RateLimitReason.codeAttemptsExceeded,
            FakeAuthRepository.resendWait,
          ),
        ),
      );
      expect(auth.resendWaitRemaining, FakeAuthRepository.resendWait);
    });

    test('a busy server asks to try again shortly', () async {
      demo.update(const DemoSettings(code: DemoCode.unavailable));

      await expectLater(
        auth.verifyCode(CodePurpose.verifyEmail, '123456'),
        throwsA(isA<ServiceUnavailableException>()),
      );
    });
  });

  group('a new code', () {
    test('is refused inside the wait, with the time left', () async {
      await register();
      now = now.add(const Duration(seconds: 10));

      await expectLater(
        auth.resendCode(CodePurpose.verifyEmail),
        throwsA(
          rateLimited(
            RateLimitReason.resendTooSoon,
            const Duration(seconds: 50),
          ),
        ),
      );
    });

    test('is sent after the wait, and starts a new wait', () async {
      await register();
      now = now.add(const Duration(seconds: 60));

      await auth.resendCode(CodePurpose.verifyEmail);

      expect(auth.resendWaitRemaining, FakeAuthRepository.resendWait);
    });

    test('asking to reset a password starts the wait too', () async {
      await auth.requestPasswordReset('me@b.c');

      expect(auth.pendingEmail, 'me@b.c');
      expect(auth.resendWaitRemaining, FakeAuthRepository.resendWait);
    });

    test(
      'asking for the same reset code again inside the wait is refused',
      () async {
        await auth.requestPasswordReset('me@b.c');

        await expectLater(
          auth.requestPasswordReset(' ME@b.c '),
          throwsA(
            isA<RateLimitedException>().having(
              (e) => e.reason,
              'reason',
              RateLimitReason.resendTooSoon,
            ),
          ),
        );
      },
    );

    test('another address is not held by the wait', () async {
      await auth.requestPasswordReset('me@b.c');
      await auth.requestPasswordReset('other@b.c');

      expect(auth.pendingEmail, 'other@b.c');
    });

    test('a busy server refuses a reset code', () async {
      demo.update(const DemoSettings(code: DemoCode.unavailable));

      await expectLater(
        auth.requestPasswordReset('me@b.c'),
        throwsA(isA<ServiceUnavailableException>()),
      );
    });

    group('the new password after a reset', () {
      test('is accepted, and ends the session like the server does', () async {
        auth = FakeAuthRepository(demo: demo, signedIn: true);

        await auth.resetPassword('anything');

        expect(auth.isSignedIn, isFalse);
      });

      for (final entry in {
        DemoPasswordReset.passwordRefused: isA<PasswordRejectedException>(),
        DemoPasswordReset.tokenInvalid: isA<ResetTokenInvalidException>(),
        DemoPasswordReset.tooSoon: isA<RateLimitedException>(),
        DemoPasswordReset.unavailable: isA<ServiceUnavailableException>(),
      }.entries) {
        test('${entry.key.name} is answered like the server does', () async {
          auth = FakeAuthRepository(demo: demo, signedIn: true);
          demo.update(DemoSettings(passwordReset: entry.key));

          await expectLater(
            auth.resetPassword('anything'),
            throwsA(entry.value),
          );

          // Refused: nothing happened to the session.
          expect(auth.isSignedIn, isTrue);
        });
      }
    });

    test('a busy server asks to try again shortly', () async {
      demo.update(const DemoSettings(code: DemoCode.unavailable));

      await expectLater(
        auth.resendCode(CodePurpose.verifyEmail),
        throwsA(isA<ServiceUnavailableException>()),
      );
    });
  });
}
