import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/bloc/app_lock_bloc.dart';
import 'package:money_scribe/features/auth/bloc/pin_bloc.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';

import '../../../support/instant_app_lock_repository.dart';

void main() {
  late InstantAppLockRepository appLock;
  late FakeAuthRepository auth;

  setUp(() {
    appLock = InstantAppLockRepository();
    auth = FakeAuthRepository(
      demo: DemoController(latency: Duration.zero),
      signedIn: true,
    );
  });

  group('AppLockBloc', () {
    blocTest<AppLockBloc, AppLockState>(
      'unlocks when the fingerprint matches',
      build: () => AppLockBloc(repository: appLock),
      act: (bloc) => bloc.add(const BiometricUnlockRequested()),
      expect: () => const [
        AppLockState(status: AppLockStatus.checking),
        AppLockState(status: AppLockStatus.unlocked),
      ],
    );

    blocTest<AppLockBloc, AppLockState>(
      'stays locked when the fingerprint does not match',
      setUp: () => appLock.biometricsMatch = false,
      build: () => AppLockBloc(repository: appLock),
      act: (bloc) => bloc.add(const BiometricUnlockRequested()),
      expect: () => const [
        AppLockState(status: AppLockStatus.checking),
        AppLockState(status: AppLockStatus.notRecognised),
      ],
    );
  });

  PinBloc unlockBloc() {
    return PinBloc(mode: PinMode.unlock, appLock: appLock, auth: auth);
  }

  PinBloc createBloc() {
    return PinBloc(mode: PinMode.create, appLock: appLock, auth: auth);
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
    );

    blocTest<PinBloc, PinState>(
      'clears a wrong PIN and says so',
      setUp: () => appLock.pin = '1234',
      build: unlockBloc,
      act: (bloc) => typePin(bloc, '9999'),
      skip: 4,
      expect: () => const [
        PinState(pin: '9999', status: PinStatus.checking),
        PinState(status: PinStatus.wrong),
      ],
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
      'Forgot PIN signs the person out',
      build: unlockBloc,
      act: (bloc) => bloc.add(const ForgotPinPressed()),
      expect: () => const [PinState(status: PinStatus.signedOut)],
      verify: (_) => expect(auth.isSignedIn, isFalse),
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
