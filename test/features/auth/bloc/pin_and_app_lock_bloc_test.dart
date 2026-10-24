import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/bloc/app_lock_bloc.dart';
import 'package:money_scribe/features/auth/bloc/pin_bloc.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/pin_check.dart';

import '../../../support/fake_app_lock_session.dart';
import '../../../support/fake_ticker.dart';
import '../../../support/instant_app_lock_repository.dart';

void main() {
  late InstantAppLockRepository appLock;
  late FakeAuthRepository auth;
  late FakeAppLockSession session;
  late FakeTicker ticker;

  setUp(() {
    appLock = InstantAppLockRepository();
    auth = FakeAuthRepository(
      demo: DemoController(latency: Duration.zero),
      signedIn: true,
    );
    session = FakeAppLockSession();
    ticker = FakeTicker();
  });

  group('AppLockBloc', () {
    AppLockBloc build() {
      return AppLockBloc(repository: appLock, session: session);
    }

    blocTest<AppLockBloc, AppLockState>(
      'asks for the fingerprint at once, and opens the app when it matches',
      build: build,
      act: (bloc) => bloc.add(const AppLockStarted(reason: 'Unlock')),
      expect: () => const [
        AppLockState(canUseBiometrics: true),
        AppLockState(status: AppLockStatus.checking, canUseBiometrics: true),
        AppLockState(status: AppLockStatus.unlocked, canUseBiometrics: true),
      ],
      verify: (_) {
        expect(session.unlocks, 1);
        expect(appLock.biometricReasons, ['Unlock']);
      },
    );

    blocTest<AppLockBloc, AppLockState>(
      'stays locked when the fingerprint does not match',
      setUp: () => appLock.biometricsMatch = false,
      build: build,
      act: (bloc) => bloc.add(const BiometricUnlockRequested(reason: 'Unlock')),
      expect: () => const [
        AppLockState(status: AppLockStatus.checking),
        AppLockState(status: AppLockStatus.notRecognised),
      ],
      verify: (_) => expect(session.unlocks, 0),
    );

    blocTest<AppLockBloc, AppLockState>(
      'a device with no fingerprint goes to the PIN and asks for none',
      setUp: () => appLock.deviceHasFingerprint = false,
      build: build,
      act: (bloc) => bloc.add(const AppLockStarted(reason: 'Unlock')),
      expect: () => const [AppLockState()],
      verify: (_) => expect(appLock.biometricReasons, isEmpty),
    );
  });

  PinBloc unlockBloc() {
    return PinBloc(
      mode: PinMode.unlock,
      appLock: appLock,
      auth: auth,
      session: session,
      ticker: ticker,
    );
  }

  PinBloc createBloc() {
    return PinBloc(
      mode: PinMode.create,
      appLock: appLock,
      auth: auth,
      session: session,
      ticker: ticker,
    );
  }

  void typePin(PinBloc bloc, String digits) {
    for (final digit in digits.split('')) {
      bloc.add(PinDigitPressed(int.parse(digit)));
    }
  }

  group('PinBloc, unlocking', () {
    blocTest<PinBloc, PinState>(
      'fills the dots digit by digit',
      build: unlockBloc,
      act: (bloc) => typePin(bloc, '12'),
      expect: () => const [PinState(pin: '1'), PinState(pin: '12')],
    );

    blocTest<PinBloc, PinState>(
      'backspace removes the last digit',
      build: unlockBloc,
      act: (bloc) => bloc
        ..add(const PinDigitPressed(1))
        ..add(const PinDigitPressed(2))
        ..add(const PinBackspacePressed()),
      expect: () => const [
        PinState(pin: '1'),
        PinState(pin: '12'),
        PinState(pin: '1'),
      ],
    );

    blocTest<PinBloc, PinState>(
      'backspace on an empty PIN does nothing',
      build: unlockBloc,
      act: (bloc) => bloc.add(const PinBackspacePressed()),
      expect: () => <PinState>[],
    );

    blocTest<PinBloc, PinState>(
      'opens the app with the right PIN',
      setUp: () => appLock.pin = '1234',
      build: unlockBloc,
      act: (bloc) => typePin(bloc, '1234'),
      expect: () => const [
        PinState(pin: '1'),
        PinState(pin: '12'),
        PinState(pin: '123'),
        PinState(pin: '1234'),
        PinState(pin: '1234', status: PinStatus.checking),
        PinState(pin: '1234', status: PinStatus.accepted),
      ],
      verify: (_) => expect(session.unlocks, 1),
    );

    blocTest<PinBloc, PinState>(
      'clears a wrong PIN and says so, without opening the app',
      setUp: () => appLock.pin = '1234',
      build: unlockBloc,
      act: (bloc) => typePin(bloc, '9999'),
      skip: 4,
      expect: () => const [
        PinState(pin: '9999', status: PinStatus.checking),
        PinState(status: PinStatus.wrong),
      ],
      verify: (_) => expect(session.unlocks, 0),
    );

    blocTest<PinBloc, PinState>(
      'a key pressed after an error starts a new try',
      setUp: () => appLock.pin = '1234',
      build: unlockBloc,
      act: (bloc) async {
        typePin(bloc, '9999');
        await pumpEventQueue();
        bloc.add(const PinDigitPressed(1));
      },
      skip: 6,
      expect: () => const [PinState(pin: '1')],
    );

    blocTest<PinBloc, PinState>(
      'Forgot PIN signs the person out, and the forgotten PIN goes',
      setUp: () => appLock.pin = '1234',
      build: unlockBloc,
      act: (bloc) => bloc.add(const ForgotPinPressed()),
      expect: () => const [PinState(status: PinStatus.signedOut)],
      verify: (_) {
        expect(auth.isSignedIn, isFalse);
        expect(appLock.pin, isNull);
      },
    );
  });

  group('PinBloc, after wrong PINs', () {
    blocTest<PinBloc, PinState>(
      'a pause the wrong PIN started is counted down, then the pad is back',
      setUp: () => appLock.queuedChecks.add(
        const PinWrong(delay: Duration(seconds: 30)),
      ),
      build: unlockBloc,
      act: (bloc) async {
        typePin(bloc, '9999');
        await pumpEventQueue();
        ticker.tick(29);
        await pumpEventQueue();
        ticker.tick(0);
      },
      skip: 5,
      expect: () => const [
        PinState(status: PinStatus.paused, pauseSecondsLeft: 30),
        PinState(status: PinStatus.paused, pauseSecondsLeft: 29),
        PinState(),
      ],
      verify: (_) => expect(ticker.started, [30]),
    );

    blocTest<PinBloc, PinState>(
      'keys are ignored during the pause',
      setUp: () =>
          appLock.queuedChecks.add(const PinWrong(delay: Duration(minutes: 1))),
      build: unlockBloc,
      act: (bloc) async {
        typePin(bloc, '9999');
        await pumpEventQueue();
        typePin(bloc, '12');
      },
      verify: (bloc) {
        expect(bloc.state.status, PinStatus.paused);
        expect(bloc.state.pin, isEmpty);
      },
    );

    blocTest<PinBloc, PinState>(
      'a pause that is still running when the screen opens is shown at once',
      setUp: () => appLock.pause = const Duration(minutes: 5),
      build: unlockBloc,
      act: (bloc) => bloc.add(const PinStarted()),
      expect: () => const [
        PinState(status: PinStatus.paused, pauseSecondsLeft: 300),
      ],
    );

    blocTest<PinBloc, PinState>(
      'a PIN typed while the repository says it is paused is not an attempt',
      setUp: () =>
          appLock.queuedChecks.add(const PinPaused(Duration(seconds: 40))),
      build: unlockBloc,
      act: (bloc) async {
        typePin(bloc, '1234');
        await pumpEventQueue();
      },
      verify: (bloc) {
        expect(bloc.state.status, PinStatus.paused);
        expect(bloc.state.pauseSecondsLeft, 40);
        expect(session.unlocks, 0);
      },
    );

    blocTest<PinBloc, PinState>(
      'too many wrong PINs sign the person out',
      setUp: () {
        appLock.pin = '1234';
        appLock.queuedChecks.add(const PinTooManyFailures());
      },
      build: unlockBloc,
      act: (bloc) async {
        typePin(bloc, '9999');
        await pumpEventQueue();
      },
      verify: (bloc) {
        expect(bloc.state.status, PinStatus.tooManyFailures);
        expect(auth.isSignedIn, isFalse);
        expect(session.unlocks, 0);
        // The lock goes with it: the person makes a new one after signing in.
        expect(appLock.pin, isNull);
      },
    );
  });

  group('PinBloc, creating', () {
    blocTest<PinBloc, PinState>(
      'asks to repeat the PIN after the first entry',
      build: createBloc,
      act: (bloc) => typePin(bloc, '4321'),
      skip: 3,
      expect: () => const [
        PinState(pin: '4321'),
        PinState(stage: PinStage.repeat),
      ],
    );

    blocTest<PinBloc, PinState>(
      'saves the PIN when the repeat matches',
      build: createBloc,
      act: (bloc) => typePin(bloc, '43214321'),
      verify: (bloc) {
        expect(bloc.state.status, PinStatus.accepted);
        expect(appLock.pin, '4321');
        // The lock belongs to the account that made it.
        expect(appLock.account, auth.accountId);
        // Creating a PIN is not unlocking the app.
        expect(session.unlocks, 0);
      },
    );

    blocTest<PinBloc, PinState>(
      'starts again when the repeat differs, and saves nothing',
      build: createBloc,
      act: (bloc) => typePin(bloc, '43211234'),
      verify: (bloc) {
        expect(bloc.state, const PinState(status: PinStatus.mismatch));
        expect(appLock.pin, isNull);
      },
    );
  });
}
