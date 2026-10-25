import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/network/slow_request_monitor.dart';

import '../../support/fake_http_adapter.dart';
import '../../support/manual_timers.dart';

void main() {
  late ManualTimers timers;
  late SlowRequestMonitor monitor;
  late List<bool> changes;

  setUp(() {
    timers = ManualTimers();
    monitor = SlowRequestMonitor(timer: timers.create);
    changes = [];
    monitor.slowChanges.listen(changes.add);
  });

  group('the monitor', () {
    test('waits five seconds before a request counts as slow', () {
      expect(SlowRequestMonitor.defaultThreshold, const Duration(seconds: 5));

      monitor.begin();

      expect(timers.created.single.duration, const Duration(seconds: 5));
      expect(monitor.isSlow, isFalse);
    });

    test('a request that answers in time never makes the server slow', () {
      final end = monitor.begin();

      end();

      expect(monitor.isSlow, isFalse);
      expect(changes, isEmpty);
      expect(timers.active, isEmpty, reason: 'its timer was cancelled');
    });

    test('a request that waits past the threshold makes the server slow', () {
      monitor.begin();

      timers.created.single.fire();

      expect(monitor.isSlow, isTrue);
      expect(changes, [true]);
    });

    test('the answer ends it', () {
      final end = monitor.begin();
      timers.created.single.fire();

      end();

      expect(monitor.isSlow, isFalse);
      expect(changes, [true, false]);
    });

    test('stays slow while any request is past the threshold', () {
      final first = monitor.begin();
      final second = monitor.begin();
      timers.created.first.fire();
      timers.created.last.fire();

      first();
      expect(monitor.isSlow, isTrue, reason: 'the second is still waiting');

      second();
      expect(monitor.isSlow, isFalse);
      expect(changes, [true, false]);
    });

    test('a new request does not make it slow until it has waited too', () {
      final slow = monitor.begin();
      timers.created.first.fire();
      monitor.begin();

      slow();

      expect(monitor.isSlow, isFalse, reason: 'the new one is not past it yet');
    });

    test('says nothing twice for the same state', () {
      monitor
        ..begin()
        ..begin();

      timers.created[0].fire();
      timers.created[1].fire();

      expect(changes, [true]);
    });

    test('ending a request twice does nothing', () {
      final end = monitor.begin();
      timers.created.single.fire();

      end();
      end();

      expect(changes, [true, false]);
    });

    test('a different threshold is used when given', () {
      SlowRequestMonitor(
        threshold: const Duration(seconds: 2),
        timer: timers.create,
      ).begin();

      expect(timers.created.last.duration, const Duration(seconds: 2));
    });

    test('dispose cancels the waiting timers', () async {
      monitor
        ..begin()
        ..begin();

      await monitor.dispose();

      expect(timers.active, isEmpty);
    });
  });

  group('the adapter', () {
    late Completer<ResponseBody> answer;
    late FakeHttpAdapter server;
    late Dio dio;

    setUp(() {
      answer = Completer<ResponseBody>();
      server = FakeHttpAdapter((options) => answer.future);
      dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = MonitoredHttpAdapter(server, monitor);
    });

    test(
      'counts a request while it waits, and stops when it is answered',
      () async {
        final call = dio.get<void>('/x');
        await pumpEventQueue();
        expect(timers.active, hasLength(1));

        timers.created.single.fire();
        expect(monitor.isSlow, isTrue);

        answer.complete(jsonBody(200));
        await call;
        expect(monitor.isSlow, isFalse);
        expect(timers.active, isEmpty);
      },
    );

    test('stops counting when the request fails', () async {
      final call = dio.get<void>('/x');
      await pumpEventQueue();
      timers.created.single.fire();

      answer.completeError(connectionLost(RequestOptions(path: '/x')));

      await expectLater(call, throwsA(isA<DioException>()));
      expect(monitor.isSlow, isFalse);
    });

    test('passes the request and the answer through unchanged', () async {
      answer.complete(jsonBody(200, {'ok': true}));

      final response = await dio.get<Map<String, dynamic>>('/x');

      expect(response.data, {'ok': true});
      expect(server.requests.single.path, '/x');
    });

    test('counts every request that goes out, a retry included', () async {
      final quick = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = MonitoredHttpAdapter(
          FakeHttpAdapter((options) => jsonBody(200)),
          monitor,
        );

      await quick.get<void>('/a');
      await quick.get<void>('/b');

      expect(timers.created, hasLength(2));
      expect(monitor.isSlow, isFalse);
    });
  });
}
