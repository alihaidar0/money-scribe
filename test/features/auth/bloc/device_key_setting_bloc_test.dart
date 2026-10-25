import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/bloc/device_key_setting_bloc.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/data/fake/fake_device_key_repository.dart';
import 'package:money_scribe/features/auth/domain/device_key.dart';

/// A sign-in that is on until the server is asked, and then no longer known.
class _DroppedByServer extends FakeDeviceKeyRepository {
  new(DemoController demo)
    : super(
        demo: demo,
        auth: FakeAuthRepository(demo: demo, signedIn: true),
      );

  bool _dropped = false;

  @override
  Future<bool> isEnabled() async => !_dropped;

  @override
  Future<void> sync() async => _dropped = true;
}

void main() {
  late DemoController demo;
  late FakeDeviceKeyRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeDeviceKeyRepository(
      demo: demo,
      auth: FakeAuthRepository(demo: demo, signedIn: true),
    );
  });

  DeviceKeySettingBloc build() => DeviceKeySettingBloc(repository: repository);

  const turnOn = FingerprintSignInTurnedOn(password: 'p', prompt: 'Confirm');

  group('a key made or removed elsewhere', () {
    test('turns the switch off when the key is removed', () async {
      await repository.enable(password: 'p', prompt: 'Confirm');
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const DeviceKeySettingRefreshed());
      await bloc.stream.firstWhere((s) => s.isLoaded && s.isEnabled);

      // The phone list removes this phone, or the password change removes it.
      await repository.removeKey(FakeDeviceKeyRepository.thisDeviceId);
      await bloc.stream.firstWhere((s) => !s.isEnabled);

      expect(bloc.state.isEnabled, isFalse);
    });

    test('turns the switch on when the key is made', () async {
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const DeviceKeySettingRefreshed());
      await bloc.stream.firstWhere((s) => s.isLoaded);
      expect(bloc.state.isEnabled, isFalse);

      await repository.enable(password: 'p', prompt: 'Confirm');
      await bloc.stream.firstWhere((s) => s.isEnabled);

      expect(bloc.state.isEnabled, isTrue);
    });
  });

  group('what the row shows', () {
    blocTest<DeviceKeySettingBloc, DeviceKeySettingState>(
      'is off until the sign-in is turned on',
      build: build,
      act: (bloc) => bloc.add(const DeviceKeySettingRefreshed()),
      expect: () => [
        const DeviceKeySettingState(
          isLoaded: true,
          support: DeviceKeySupport.available,
        ),
      ],
    );

    blocTest<DeviceKeySettingBloc, DeviceKeySettingState>(
      'says when no fingerprint is enrolled',
      setUp: () => demo.update(
        const DemoSettings(fingerprint: DemoFingerprint.notEnrolled),
      ),
      build: build,
      act: (bloc) => bloc.add(const DeviceKeySettingRefreshed()),
      verify: (bloc) {
        expect(bloc.state.support, DeviceKeySupport.notEnrolled);
        expect(bloc.state.canTurnOn, isFalse);
      },
    );

    blocTest<DeviceKeySettingBloc, DeviceKeySettingState>(
      'says when the phone cannot hold the key',
      setUp: () => demo.update(
        const DemoSettings(fingerprint: DemoFingerprint.unsupported),
      ),
      build: build,
      act: (bloc) => bloc.add(const DeviceKeySettingRefreshed()),
      verify: (bloc) => expect(bloc.state.canTurnOn, isFalse),
    );

    blocTest<DeviceKeySettingBloc, DeviceKeySettingState>(
      'reads back a sign-in that is on',
      build: build,
      act: (bloc) async {
        await repository.enable(password: 'p', prompt: 'Confirm');
        bloc.add(const DeviceKeySettingRefreshed());
      },
      verify: (bloc) => expect(bloc.state.isEnabled, isTrue),
    );

    blocTest<DeviceKeySettingBloc, DeviceKeySettingState>(
      'turns off when the server no longer knows the key',
      build: () => DeviceKeySettingBloc(repository: _DroppedByServer(demo)),
      act: (bloc) => bloc.add(const DeviceKeySettingRefreshed()),
      expect: () => [
        isA<DeviceKeySettingState>().having((s) => s.isEnabled, 'on', true),
        isA<DeviceKeySettingState>().having((s) => s.isEnabled, 'on', false),
      ],
    );

    test('cannot be switched before the first answer', () {
      expect(const DeviceKeySettingState().canTurnOn, isFalse);
    });
  });

  group('turning it on', () {
    blocTest<DeviceKeySettingBloc, DeviceKeySettingState>(
      'goes through busy and ends on',
      build: build,
      seed: () => const DeviceKeySettingState(
        isLoaded: true,
        support: DeviceKeySupport.available,
      ),
      act: (bloc) => bloc.add(turnOn),
      expect: () => [
        isA<DeviceKeySettingState>().having((s) => s.isBusy, 'busy', true),
        isA<DeviceKeySettingState>()
            .having((s) => s.isBusy, 'busy', false)
            .having((s) => s.isEnabled, 'on', true)
            .having((s) => s.outcome, 'outcome', DeviceKeyOutcome.turnedOn),
      ],
    );

    final cases = <DemoFingerprint, DeviceKeyOutcome>{
      DemoFingerprint.notMatched: DeviceKeyOutcome.notMatched,
      DemoFingerprint.attestationRefused: DeviceKeyOutcome.refused,
      DemoFingerprint.limitReached: DeviceKeyOutcome.limitReached,
      DemoFingerprint.unavailable: DeviceKeyOutcome.busy,
    };
    for (final MapEntry(key: demoOutcome, value: outcome) in cases.entries) {
      blocTest<DeviceKeySettingBloc, DeviceKeySettingState>(
        '$demoOutcome stays off and says $outcome',
        setUp: () => demo.update(DemoSettings(fingerprint: demoOutcome)),
        build: build,
        act: (bloc) => bloc.add(turnOn),
        verify: (bloc) {
          expect(bloc.state.isEnabled, isFalse);
          expect(bloc.state.isBusy, isFalse);
          expect(bloc.state.outcome, outcome);
        },
      );
    }

    blocTest<DeviceKeySettingBloc, DeviceKeySettingState>(
      'a wrong password stays off',
      setUp: () =>
          demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword)),
      build: build,
      act: (bloc) => bloc.add(turnOn),
      verify: (bloc) {
        expect(bloc.state.isEnabled, isFalse);
        expect(bloc.state.outcome, DeviceKeyOutcome.wrongPassword);
      },
    );

    blocTest<DeviceKeySettingBloc, DeviceKeySettingState>(
      'a phone with no fingerprint enrolled cannot check one',
      setUp: () => demo.update(
        const DemoSettings(fingerprint: DemoFingerprint.notEnrolled),
      ),
      build: build,
      act: (bloc) => bloc.add(turnOn),
      verify: (bloc) =>
          expect(bloc.state.outcome, DeviceKeyOutcome.cannotCheck),
    );

    blocTest<DeviceKeySettingBloc, DeviceKeySettingState>(
      'a lost connection says so and stays off',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(turnOn),
      verify: (bloc) {
        expect(bloc.state.isEnabled, isFalse);
        expect(bloc.state.outcome, DeviceKeyOutcome.offline);
      },
    );

    blocTest<DeviceKeySettingBloc, DeviceKeySettingState>(
      'a failing server says something went wrong',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(turnOn),
      // A failure the screen has no word for is reported, not swallowed.
      errors: () => [isA<ServerException>()],
      verify: (bloc) => expect(bloc.state.outcome, DeviceKeyOutcome.failed),
    );

    blocTest<DeviceKeySettingBloc, DeviceKeySettingState>(
      'a second press while the first is working is ignored',
      build: build,
      act: (bloc) => bloc
        ..add(turnOn)
        ..add(turnOn),
      verify: (bloc) => expect(bloc.state.isEnabled, isTrue),
    );
  });

  group('turning it off', () {
    blocTest<DeviceKeySettingBloc, DeviceKeySettingState>(
      'ends off and says so',
      build: build,
      act: (bloc) async {
        bloc.add(turnOn);
        await bloc.stream.firstWhere((s) => s.isEnabled);
        bloc.add(const FingerprintSignInTurnedOff());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.isEnabled, isFalse);
        expect(bloc.state.outcome, DeviceKeyOutcome.turnedOff);
      },
    );

    blocTest<DeviceKeySettingBloc, DeviceKeySettingState>(
      'stays on when the server cannot be reached',
      build: build,
      act: (bloc) async {
        bloc.add(turnOn);
        await bloc.stream.firstWhere((s) => s.isEnabled);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(const FingerprintSignInTurnedOff());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.isEnabled, isTrue);
        expect(bloc.state.outcome, DeviceKeyOutcome.offline);
      },
    );
  });
}
