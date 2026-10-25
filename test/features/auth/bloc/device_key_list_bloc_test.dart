import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/bloc/device_key_list_bloc.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/data/fake/fake_device_key_repository.dart';
import 'package:money_scribe/features/auth/domain/device_key_repository.dart';

/// A server that cannot remove a phone: it fails as [failure] says.
class _FailingRemoval extends FakeDeviceKeyRepository {
  new({required super.demo, required super.auth, required this.failure});

  final Exception failure;

  @override
  Future<void> removeKey(String deviceId) => throw failure;
}

void main() {
  late DemoController demo;
  late FakeAuthRepository auth;
  late FakeDeviceKeyRepository keys;

  setUp(() async {
    demo = DemoController(latency: Duration.zero);
    auth = FakeAuthRepository(demo: demo, signedIn: true);
    keys = FakeDeviceKeyRepository(demo: demo, auth: auth);
    await keys.enable(password: 'p', prompt: 'Confirm');
  });

  DeviceKeyListBloc build([DeviceKeyRepository? repository]) {
    return DeviceKeyListBloc(repository: repository ?? keys);
  }

  /// A phone with the fingerprint sign-in on whose server cannot remove one.
  Future<DeviceKeyRepository> failingRemoval(Exception failure) async {
    final failing = _FailingRemoval(demo: demo, auth: auth, failure: failure);
    await failing.enable(password: 'p', prompt: 'Confirm');
    return failing;
  }

  Future<DeviceKeyListBloc> loaded([DeviceKeyRepository? repository]) async {
    final bloc = build(repository);
    addTearDown(bloc.close);
    bloc.add(const DeviceKeyListStarted());
    await bloc.stream.firstWhere((s) => s.status == DeviceKeyListStatus.ready);
    return bloc;
  }

  group('DeviceKeyListStarted', () {
    test('starts loading', () {
      final bloc = build();
      addTearDown(bloc.close);

      expect(bloc.state.status, DeviceKeyListStatus.loading);
    });

    blocTest<DeviceKeyListBloc, DeviceKeyListState>(
      'loads the phones, this one among them',
      build: build,
      act: (bloc) => bloc.add(const DeviceKeyListStarted()),
      verify: (bloc) {
        expect(bloc.state.status, DeviceKeyListStatus.ready);
        expect(bloc.state.keys, hasLength(3));
        expect(
          bloc.state.keys.where((key) => key.isCurrent).single.deviceId,
          FakeDeviceKeyRepository.thisDeviceId,
        );
      },
    );

    blocTest<DeviceKeyListBloc, DeviceKeyListState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const DeviceKeyListStarted()),
      verify: (bloc) =>
          expect(bloc.state.status, DeviceKeyListStatus.noConnection),
    );

    blocTest<DeviceKeyListBloc, DeviceKeyListState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const DeviceKeyListStarted()),
      verify: (bloc) => expect(bloc.state.status, DeviceKeyListStatus.failure),
      errors: () => [isA<ServerException>()],
    );

    test('Try again loads once the server answers', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const DeviceKeyListStarted());
      await bloc.stream.firstWhere(
        (s) => s.status == DeviceKeyListStatus.noConnection,
      );

      demo.update(const DemoSettings());
      bloc.add(const DeviceKeyListRetried());
      await bloc.stream.firstWhere(
        (s) => s.status == DeviceKeyListStatus.ready,
      );

      expect(bloc.state.keys, hasLength(3));
    });
  });

  group('DeviceKeyRemoved', () {
    test('removes another phone from the list and says so once', () async {
      final bloc = await loaded();

      bloc.add(const DeviceKeyRemoved('fake-other-android'));
      await bloc.stream.firstWhere((s) => s.removedCount == 1);

      expect(
        bloc.state.keys.map((key) => key.deviceId),
        isNot(contains('fake-other-android')),
      );
      expect(bloc.state.keys, hasLength(2));
      expect(bloc.state.removingId, isNull);
      expect(bloc.state.failedAction, isNull);
      // The server forgot it too.
      expect((await keys.keys()).map((key) => key.deviceId), hasLength(2));
    });

    test('removing this phone turns the sign-in off here', () async {
      final bloc = await loaded();

      bloc.add(const DeviceKeyRemoved(FakeDeviceKeyRepository.thisDeviceId));
      await bloc.stream.firstWhere((s) => s.removedCount == 1);

      expect(bloc.state.keys.where((key) => key.isCurrent), isEmpty);
      expect(await keys.isEnabled(), isFalse);
      expect(await keys.signInAccount(), isNull);
    });

    test('shows the phone as being removed while the server works', () async {
      final slow = DemoController(latency: const Duration(milliseconds: 20));
      final slowAuth = FakeAuthRepository(demo: slow, signedIn: true);
      final slowKeys = FakeDeviceKeyRepository(demo: slow, auth: slowAuth);
      await slowKeys.enable(password: 'p', prompt: 'Confirm');
      final bloc = await loaded(slowKeys);
      final removing = <String?>[];
      final listening = bloc.stream.listen((s) => removing.add(s.removingId));

      bloc.add(const DeviceKeyRemoved('fake-other-ios'));
      await bloc.stream.firstWhere((s) => s.removedCount == 1);
      await listening.cancel();

      expect(removing.first, 'fake-other-ios');
      expect(removing.last, isNull);
    });

    test('ignores a phone that is not in the list', () async {
      final bloc = await loaded();
      final before = bloc.state;

      bloc.add(const DeviceKeyRemoved('nobody'));
      await pumpEventQueue();

      expect(bloc.state, before);
    });

    test('removes several phones one after the other', () async {
      final bloc = await loaded();

      bloc
        ..add(const DeviceKeyRemoved('fake-other-android'))
        ..add(const DeviceKeyRemoved('fake-other-ios'));
      await bloc.stream.firstWhere((s) => s.removedCount == 2);

      expect(bloc.state.keys.map((key) => key.isCurrent), [true]);
    });

    test('a lost connection keeps the list and can be retried', () async {
      final bloc = await loaded(
        await failingRemoval(const NoConnectionException()),
      );

      bloc.add(const DeviceKeyRemoved('fake-other-android'));
      await bloc.stream.firstWhere((s) => s.failedAction != null);

      expect(bloc.state.keys, hasLength(3));
      expect(bloc.state.failure, DeviceKeyListFailure.offline);
      expect(
        bloc.state.failedAction,
        const DeviceKeyRemoved('fake-other-android'),
      );
      expect(bloc.state.removingId, isNull);
      expect(bloc.state.removedCount, 0);
    });

    test('a busy server is told apart from a failure', () async {
      final busy = await loaded(
        await failingRemoval(const ServiceUnavailableException()),
      );
      busy.add(const DeviceKeyRemoved('fake-other-android'));
      await busy.stream.firstWhere((s) => s.failedAction != null);
      expect(busy.state.failure, DeviceKeyListFailure.busy);

      final failing = await loaded(
        await failingRemoval(const ServerException()),
      );
      failing.add(const DeviceKeyRemoved('fake-other-android'));
      await failing.stream.firstWhere((s) => s.failedAction != null);
      expect(failing.state.failure, DeviceKeyListFailure.other);
    });

    test('the next removal clears the failure', () async {
      demo.update(const DemoSettings(save: DemoSave.fails));
      final bloc = await loaded();
      bloc.add(const DeviceKeyRemoved('fake-other-android'));
      await bloc.stream.firstWhere((s) => s.failedAction != null);

      demo.update(const DemoSettings());
      bloc.add(const DeviceKeyRemoved('fake-other-android'));
      await bloc.stream.firstWhere((s) => s.removedCount == 1);

      expect(bloc.state.failedAction, isNull);
      expect(bloc.state.failure, isNull);
    });
  });
}
