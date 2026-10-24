import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/device/time_zone_source.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/network/omit_nulls_interceptor.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/settings/data/remote/remote_default_currency_repository.dart';
import 'package:money_scribe/features/settings/data/remote/remote_pay_schedule_repository.dart';
import 'package:money_scribe/features/settings/data/remote/remote_settings.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule.dart';

import '../../../support/fake_http_adapter.dart';

const _path = '/api/v1/settings/';

class _Zone implements TimeZoneSource {
  new(this.name);

  final String? name;

  @override
  Future<String?> read() async => name;
}

Map<String, Object?> _settings({
  int version = 3,
  String language = 'en',
  String timeZone = 'Europe/Moscow',
  String currency = 'RUB',
  String paymentMode = 'one_payment',
  int firstPayDay = 20,
  int secondPayDay = 5,
  bool remind = false,
}) {
  return {
    'language': language,
    'time_zone': timeZone,
    'default_currency': currency,
    'payment_mode': paymentMode,
    'first_pay_day': firstPayDay,
    'second_pay_day': secondPayDay,
    'remind_on_pay_days': remind,
    'version': version,
    'updated_at': '2026-10-24T08:00:00Z',
  };
}

void main() {
  late FakeHttpAdapter server;
  late Map<String, Object?> stored;
  late List<ResponseBody Function()> patchAnswers;
  late String language;
  late bool signedIn;
  late String? zone;

  RemoteSettings build() {
    final dio =
        Dio(
            BaseOptions(
              baseUrl: 'https://api.example.test',
              contentType: Headers.jsonContentType,
            ),
          )
          ..interceptors.add(const OmitNullsInterceptor())
          ..httpClientAdapter = server;
    return RemoteSettings.create(
      dio: dio,
      timeZone: _Zone(zone),
      language: () => language,
      isSignedIn: () => signedIn,
    );
  }

  List<RequestOptions> patches() =>
      server.requests.where((r) => r.method == 'PATCH').toList();

  Map<String, dynamic> lastPatchBody() =>
      patches().last.data as Map<String, dynamic>;

  setUp(() {
    stored = _settings();
    patchAnswers = [];
    language = 'en';
    signedIn = true;
    zone = 'Europe/Berlin';
    server = FakeHttpAdapter((options) {
      if (options.method == 'GET') return jsonBody(200, stored);
      if (patchAnswers.isEmpty) return jsonBody(200, stored);
      return patchAnswers.removeAt(0)();
    });
  });

  group('pay schedule', () {
    test('loads the schedule of the account', () async {
      stored = _settings(
        paymentMode: 'two_payments',
        firstPayDay: 18,
        secondPayDay: 3,
        remind: true,
      );

      final schedule = await RemotePayScheduleRepository(build()).load();

      expect(
        schedule,
        const PaySchedule(
          mode: PaymentMode.twoPayments,
          firstPayDay: 18,
          secondPayDay: 3,
          remindOnPayDays: true,
        ),
      );
    });

    test('saves it with the version that was read', () async {
      stored = _settings(version: 7);

      await RemotePayScheduleRepository(build()).save(
        const PaySchedule(
          mode: PaymentMode.twoPayments,
          firstPayDay: 15,
          secondPayDay: 2,
          remindOnPayDays: true,
        ),
      );

      expect(patches(), hasLength(1));
      expect(patches().single.path, _path);
      expect(patches().single.headers['If-Match'], '"7"');
      expect(lastPatchBody(), {
        'language': 'en',
        'time_zone': 'Europe/Berlin',
        'payment_mode': 'two_payments',
        'first_pay_day': 15,
        'second_pay_day': 2,
        'remind_on_pay_days': true,
      });
    });

    test('a save leaves the default currency out', () async {
      await RemotePayScheduleRepository(build()).save(const PaySchedule());

      expect(lastPatchBody().containsKey('default_currency'), isFalse);
    });
  });

  group('default currency', () {
    test('loads the currency of the account', () async {
      stored = _settings(currency: 'KWD');

      expect(
        await RemoteDefaultCurrencyRepository(build()).load(),
        Currency.kwd,
      );
    });

    test('a currency the app does not know is a server failure', () async {
      stored = _settings(currency: 'XYZ');

      await expectLater(
        RemoteDefaultCurrencyRepository(build()).load(),
        throwsA(isA<ServerException>()),
      );
    });

    test('saves it and keeps the reminder as it is', () async {
      stored = _settings(remind: true, paymentMode: 'two_payments');

      await RemoteDefaultCurrencyRepository(build()).save(Currency.usd);

      expect(lastPatchBody(), {
        'language': 'en',
        'time_zone': 'Europe/Berlin',
        'default_currency': 'USD',
        'remind_on_pay_days': true,
      });
    });
  });

  group('an edit made meanwhile', () {
    test('is read again and the edit is sent once more', () async {
      patchAnswers = [
        () => jsonBody(412, errorBody('precondition_failed')),
        () => jsonBody(200, _settings(version: 5)),
      ];

      await RemoteDefaultCurrencyRepository(build()).save(Currency.eur);

      expect(patches(), hasLength(2));
      expect(server.requests.where((r) => r.method == 'GET'), hasLength(2));
    });

    test('is reported when it happens twice', () async {
      patchAnswers = [
        () => jsonBody(412, errorBody('precondition_failed')),
        () => jsonBody(412, errorBody('precondition_failed')),
      ];

      await expectLater(
        RemoteDefaultCurrencyRepository(build()).save(Currency.eur),
        throwsA(isA<StaleRecordException>()),
      );
      expect(patches(), hasLength(2));
    });
  });

  group('failures', () {
    test('a lost connection is "no connection"', () async {
      server = FakeHttpAdapter((options) => throw connectionLost(options));

      await expectLater(
        RemotePayScheduleRepository(build()).load(),
        throwsA(isA<NoConnectionException>()),
      );
    });

    test('a failing server is a server failure', () async {
      server = FakeHttpAdapter((_) => jsonBody(500, errorBody('error')));

      await expectLater(
        RemotePayScheduleRepository(build()).load(),
        throwsA(isA<ServerException>()),
      );
    });

    test('a busy server is reported as busy', () async {
      server = FakeHttpAdapter((_) => jsonBody(503, errorBody('error')));

      await expectLater(
        RemotePayScheduleRepository(build()).load(),
        throwsA(isA<ServiceUnavailableException>()),
      );
    });
  });

  group('the language and time zone of the account', () {
    test('an unreadable time zone keeps the one of the server', () async {
      zone = null;
      stored = _settings(timeZone: 'Asia/Tokyo');

      await RemoteDefaultCurrencyRepository(build()).save(Currency.gbp);

      expect(lastPatchBody()['time_zone'], 'Asia/Tokyo');
    });

    test('nothing is sent while nobody is signed in', () async {
      signedIn = false;

      await build().sync();

      expect(server.requests, isEmpty);
    });

    test('nothing is sent when the server already has them', () async {
      stored = _settings(timeZone: 'Europe/Berlin');

      await build().sync();

      expect(patches(), isEmpty);
    });

    test('a changed language is sent', () async {
      language = 'ar';

      await build().sync();

      expect(lastPatchBody()['language'], 'ar');
      expect(lastPatchBody()['time_zone'], 'Europe/Berlin');
      expect(lastPatchBody().containsKey('payment_mode'), isFalse);
      expect(patches().single.headers['If-Match'], '"3"');
    });

    test('a changed time zone is sent', () async {
      // The server holds Moscow; the device is in Berlin.
      stored = _settings();

      await build().sync();

      expect(lastPatchBody()['time_zone'], 'Europe/Berlin');
    });

    test('a language the app lacks is English', () async {
      language = 'en';
      stored = _settings(language: 'ar', timeZone: 'Europe/Berlin');

      await build().sync();

      expect(lastPatchBody()['language'], 'en');
    });
  });
}
