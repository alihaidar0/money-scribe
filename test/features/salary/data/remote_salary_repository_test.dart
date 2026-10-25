import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/salary/data/remote/remote_salary_repository.dart';
import 'package:money_scribe/features/salary/domain/salary_inputs.dart';
import 'package:money_scribe/features/salary/domain/salary_month.dart';

import '../../../support/fake_http_adapter.dart';
import 'salary_json.dart';

const _october = YearMonth(2026, 10);

Money _rub(int units) => Money(units * 100, Currency.rub);

SalaryMonth _month({
  int? version,
  PaymentMode mode = PaymentMode.twoPayments,
  int firstHalf = 10,
}) {
  return SalaryMonth(
    month: _october,
    inputs: SalaryInputs(
      baseSalary: _rub(100000),
      foodPerDay: _rub(500),
      workingDaysInMonth: 20,
      workingHoursInMonth: 160,
      extraHoursHundredths: 800,
      taxRateBasisPoints: 1300,
      paymentMode: mode,
      workingDaysFirstHalf: firstHalf,
    ),
    firstPayDay: 20,
    secondPayDay: 5,
    version: version,
  );
}

/// [month] as it was typed, without the figures the server calculated, which
/// have their own tests.
SalaryMonth _withoutFigures(SalaryMonth month) {
  return SalaryMonth(
    month: month.month,
    inputs: month.inputs,
    firstPayDay: month.firstPayDay,
    secondPayDay: month.secondPayDay,
    version: month.version,
  );
}

void main() {
  late FakeHttpAdapter server;
  late ResponseBody Function(RequestOptions options) answer;

  RemoteSalaryRepository build() {
    return RemoteSalaryRepository.create(dio: salaryTestDio(server));
  }

  RequestOptions lastRequest() => server.requests.last;

  setUp(() {
    answer = (_) => jsonBody(200, salaryMonthJson());
    server = FakeHttpAdapter((options) => answer(options));
  });

  group('month', () {
    test('reads the month the server holds', () async {
      answer = (_) => jsonBody(200, salaryMonthJson(version: 4));

      final month = await build().month(_october);

      expect(lastRequest().method, 'GET');
      expect(lastRequest().path, '/api/v1/salary/months/2026-10/');
      expect(_withoutFigures(month!), _month(version: 4));
    });

    test('a month that was not saved is null', () async {
      answer = (_) => jsonBody(404, errorBody('not_found'));

      expect(await build().month(_october), isNull);
    });

    test('a month with one payment has no days of the first half', () async {
      answer = (_) => jsonBody(
        200,
        salaryMonthJson(paymentMode: 'one_payment', workingDaysFirstHalf: null),
      );

      final month = await build().month(_october);

      expect(month!.inputs.paymentMode, PaymentMode.onePayment);
      expect(month.inputs.workingDaysFirstHalf, 0);
    });

    test('an amount that does not fit its currency breaks the contract', () {
      answer = (_) => jsonBody(200, salaryMonthJson(currency: 'JPY'));

      expect(build().month(_october), throwsA(isA<ServerException>()));
    });

    test('a currency the app does not know breaks the contract', () {
      answer = (_) => jsonBody(200, salaryMonthJson(currency: 'XYZ'));

      expect(build().month(_october), throwsA(isA<ServerException>()));
    });

    test('a lost connection is "no connection"', () {
      answer = (options) => throw connectionLost(options);

      expect(build().month(_october), throwsA(isA<NoConnectionException>()));
    });

    test('a failing server is a server failure', () {
      answer = (_) => jsonBody(500, errorBody('error'));

      expect(build().month(_october), throwsA(isA<ServerException>()));
    });
  });

  group('savedMonths', () {
    test(
      'reads every page, the newest first as the server sends them',
      () async {
        answer = (options) {
          if (options.queryParameters['cursor'] == null) {
            return jsonBody(200, {
              'next':
                  'https://api.example.test/api/v1/salary/months/?cursor=abc',
              'previous': null,
              'results': [salaryMonthJson()],
            });
          }
          return jsonBody(200, {
            'next': null,
            'previous': null,
            'results': [salaryMonthJson(month: '2026-09')],
          });
        };

        final months = await build().savedMonths();

        expect(
          [for (final month in months) month.month],
          [const YearMonth(2026, 10), const YearMonth(2026, 9)],
        );
        expect(server.requests, hasLength(2));
        expect(server.requests.last.queryParameters['cursor'], 'abc');
        expect(server.requests.first.queryParameters['limit'], 100);
      },
    );

    test('an empty history is an empty list', () async {
      answer = (_) => jsonBody(200, {
        'next': null,
        'previous': null,
        'results': <Object?>[],
      });

      expect(await build().savedMonths(), isEmpty);
    });

    test('a next page that repeats itself is a failure, not a wait', () {
      answer = (_) => jsonBody(200, {
        'next': 'https://api.example.test/api/v1/salary/months/?cursor=abc',
        'previous': null,
        'results': [salaryMonthJson()],
      });

      expect(build().savedMonths(), throwsA(isA<ServerException>()));
    });
  });

  group('the figures the server calculated', () {
    test(
      'are the lines of the salary, the payments and the balances',
      () async {
        answer = (_) => jsonBody(200, salaryMonthJson());

        final figures = (await build().month(_october))!.figures!;

        expect(figures.result.foodAllowance, _rub(10000));
        expect(figures.result.extraHoursPay, _rub(10000));
        expect(figures.result.incomeBeforeTax, _rub(120000));
        expect(figures.result.tax, _rub(15600));
        expect(figures.result.totalAfterTax, _rub(104400));
        expect(figures.result.payments, [_rub(43500), _rub(60900)]);
        expect(figures.balances.first, _rub(43500));
        expect(figures.balances.second, _rub(60900));
        expect(figures.balances.month, _rub(104400));
      },
    );

    test(
      'of a month with one payment have one payment and no second balance',
      () async {
        answer = (_) => jsonBody(
          200,
          salaryMonthJson(
            paymentMode: 'one_payment',
            workingDaysFirstHalf: null,
          ),
        );

        final figures = (await build().month(_october))!.figures!;

        expect(figures.result.payments, [_rub(104400)]);
        expect(figures.balances.first, _rub(104400));
        expect(figures.balances.second, isNull);
      },
    );

    test('keep a balance below zero and the kopecks', () async {
      answer = (_) => jsonBody(
        200,
        salaryMonthJson(
          balances: {
            'first': '-1500.25',
            'second': '60900.00',
            'month': '59399.75',
          },
        ),
      );

      final balances = (await build().month(_october))!.figures!.balances;

      expect(balances.first, const Money(-150025, Currency.rub));
      expect(balances.month, const Money(5939975, Currency.rub));
    });

    test('are read in the answer of a save', () async {
      answer = (_) => jsonBody(201, salaryMonthJson());

      final saved = await build().save(_month());

      expect(saved.figures!.result.totalAfterTax, _rub(104400));
    });

    test('are read for every month of the history', () async {
      answer = (_) => jsonBody(200, {
        'next': null,
        'previous': null,
        'results': [salaryMonthJson(), salaryMonthJson(month: '2026-09')],
      });

      final months = await build().savedMonths();

      expect(
        months.map((month) => month.figures?.result.totalAfterTax),
        everyElement(_rub(104400)),
      );
    });

    test('payments that do not add up to the total break the contract', () {
      answer = (_) => jsonBody(
        200,
        salaryMonthJson(
          payments: [
            {'part': 'first', 'amount': '43500.00'},
            {'part': 'second', 'amount': '60900.01'},
          ],
        ),
      );

      expect(build().month(_october), throwsA(isA<ServerException>()));
    });

    test('a payment that the mode does not have breaks the contract', () {
      // Two payments listed for a month paid in one.
      answer = (_) => jsonBody(
        200,
        salaryMonthJson(
          paymentMode: 'one_payment',
          workingDaysFirstHalf: null,
          payments: [
            {'part': 'first', 'amount': '43500.00'},
            {'part': 'second', 'amount': '60900.00'},
          ],
        ),
      );

      expect(build().month(_october), throwsA(isA<ServerException>()));
    });

    test('a missing payment breaks the contract', () {
      answer = (_) => jsonBody(
        200,
        salaryMonthJson(
          payments: [
            {'part': 'first', 'amount': '104400.00'},
          ],
        ),
      );

      expect(build().month(_october), throwsA(isA<ServerException>()));
    });

    test('a balance that is not an amount breaks the contract', () {
      answer = (_) => jsonBody(
        200,
        salaryMonthJson(
          balances: {'first': 'x', 'second': '60900.00', 'month': '104400.00'},
        ),
      );

      expect(build().month(_october), throwsA(isA<ServerException>()));
    });
  });

  group('defaults', () {
    test('asks for the month and reads what the server pre-fills', () async {
      answer = (_) => jsonBody(200, {
        'currency': 'RUB',
        'base_salary': '100000.00',
        'food_per_day': '500.00',
        'working_days_in_month': null,
        'working_hours_in_month': 160,
        'extra_hours_hundredths': 0,
        'tax_rate_basis_points': 1300,
        'payment_mode': 'two_payments',
        'working_days_first_half': null,
        'first_pay_day': 18,
        'second_pay_day': 3,
      });

      final defaults = await build().defaults(_october);

      expect(lastRequest().path, '/api/v1/salary/months/2026-10/defaults/');
      expect(defaults.paymentMode, PaymentMode.twoPayments);
      expect(defaults.firstPayDay, 18);
      expect(defaults.secondPayDay, 3);
      expect(defaults.baseSalary, _rub(100000));
      expect(defaults.foodPerDay, _rub(500));
      expect(defaults.workingHoursInMonth, 160);
      expect(defaults.taxRateBasisPoints, 1300);
    });

    test('has no figures when no month was saved before', () async {
      answer = (_) => jsonBody(200, {
        'currency': 'USD',
        'base_salary': null,
        'food_per_day': null,
        'working_days_in_month': null,
        'working_hours_in_month': null,
        'extra_hours_hundredths': 0,
        'tax_rate_basis_points': 1300,
        'payment_mode': 'one_payment',
        'working_days_first_half': null,
        'first_pay_day': 20,
        'second_pay_day': 5,
      });

      final defaults = await build().defaults(_october);

      expect(defaults.currency, Currency.usd);
      expect(defaults.baseSalary, isNull);
      expect(defaults.foodPerDay, isNull);
      expect(defaults.workingHoursInMonth, isNull);
    });
  });

  group('save', () {
    test('a new month is created only if none exists', () async {
      answer = (_) => jsonBody(201, salaryMonthJson());

      final saved = await build().save(_month());

      expect(lastRequest().method, 'PUT');
      expect(lastRequest().path, '/api/v1/salary/months/2026-10/');
      expect(lastRequest().headers['If-None-Match'], '*');
      expect(lastRequest().headers.containsKey('If-Match'), isFalse);
      expect(_withoutFigures(saved), _month(version: 1));
    });

    test('sends the inputs, with the amounts as decimal strings', () async {
      await build().save(_month());

      expect(lastRequest().data, {
        'currency': 'RUB',
        'base_salary': '100000.00',
        'food_per_day': '500.00',
        'working_days_in_month': 20,
        'working_hours_in_month': 160,
        'extra_hours_hundredths': 800,
        'tax_rate_basis_points': 1300,
        'payment_mode': 'two_payments',
        'working_days_first_half': 10,
        'first_pay_day': 20,
        'second_pay_day': 5,
      });
    });

    test('one payment sends no days of the first half', () async {
      await build().save(_month(mode: PaymentMode.onePayment, firstHalf: 0));

      final body = lastRequest().data as Map<String, dynamic>;
      expect(body['payment_mode'], 'one_payment');
      expect(body.containsKey('working_days_first_half'), isFalse);
    });

    test(
      'a saved month is replaced only at the version that was read',
      () async {
        answer = (_) => jsonBody(200, salaryMonthJson(version: 5));

        final saved = await build().save(_month(version: 4));

        expect(lastRequest().headers['If-Match'], '"4"');
        expect(lastRequest().headers.containsKey('If-None-Match'), isFalse);
        expect(saved.version, 5);
      },
    );

    test('a month created meanwhile elsewhere is a stale record', () {
      answer = (_) => jsonBody(412, errorBody('precondition_failed'));

      expect(build().save(_month()), throwsA(isA<StaleRecordException>()));
    });

    test('a month changed meanwhile elsewhere is a stale record', () {
      answer = (_) => jsonBody(412, errorBody('precondition_failed'));

      expect(
        build().save(_month(version: 4)),
        throwsA(isA<StaleRecordException>()),
      );
    });

    test('a lost connection is "no connection"', () {
      answer = (options) => throw connectionLost(options);

      expect(build().save(_month()), throwsA(isA<NoConnectionException>()));
    });
  });

  group('delete', () {
    test('deletes at the version that was read', () async {
      answer = (_) => ResponseBody.fromString('', 204);

      await build().delete(_october, version: 4);

      expect(lastRequest().method, 'DELETE');
      expect(lastRequest().path, '/api/v1/salary/months/2026-10/');
      expect(lastRequest().headers['If-Match'], '"4"');
    });

    test('a month that is gone is already deleted', () async {
      answer = (_) => jsonBody(404, errorBody('not_found'));

      await build().delete(_october, version: 4);
    });

    test('a month changed meanwhile elsewhere is a stale record', () {
      answer = (_) => jsonBody(412, errorBody('precondition_failed'));

      expect(
        build().delete(_october, version: 4),
        throwsA(isA<StaleRecordException>()),
      );
    });
  });

  test('has no pushed changes', () {
    expect(build().changes, emitsDone);
  });
}
