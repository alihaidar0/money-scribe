import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/salary/domain/salary_calculator.dart';
import 'package:money_scribe/features/salary/domain/salary_inputs.dart';
import 'package:money_scribe/features/salary/domain/salary_result.dart';

/// An amount from minor units (kopecks): `_rub(1050)` is 10.50 ₽.
Money _rub(int kopecks) => Money(kopecks, Currency.rub);

/// Invented numbers that need no rounding.
SalaryInputs _caseA({PaymentMode mode = PaymentMode.onePayment}) {
  return SalaryInputs(
    baseSalary: _rub(10000000),
    foodPerDay: _rub(50000),
    workingDaysInMonth: 20,
    workingDaysFirstHalf: 10,
    workingHoursInMonth: 160,
    extraHoursHundredths: 800,
    taxRateBasisPoints: 1300,
    paymentMode: mode,
  );
}

/// Invented numbers that make several lines round.
SalaryInputs _caseB({PaymentMode mode = PaymentMode.onePayment}) {
  return SalaryInputs(
    baseSalary: _rub(9876500),
    foodPerDay: _rub(34500),
    workingDaysInMonth: 21,
    workingDaysFirstHalf: 9,
    workingHoursInMonth: 168,
    extraHoursHundredths: 700,
    taxRateBasisPoints: 1300,
    paymentMode: mode,
  );
}

SalaryResult _calculate(SalaryInputs inputs) {
  final calculation = SalaryCalculator.calculate(inputs);
  return switch (calculation) {
    SalaryComputed(:final result) => result,
    SalaryRejected(:final problems) => fail('Rejected: $problems'),
  };
}

Set<SalaryInputProblem> _problemsOf(SalaryInputs inputs) {
  final calculation = SalaryCalculator.calculate(inputs);
  return switch (calculation) {
    SalaryRejected(:final problems) => problems,
    SalaryComputed() => fail('Expected the inputs to be rejected'),
  };
}

void main() {
  group('Case A (exact, no rounding)', () {
    test('calculates every line', () {
      final result = _calculate(_caseA());

      expect(result.foodAllowance, _rub(1000000));
      expect(result.extraHoursPay, _rub(1000000));
      expect(result.incomeBeforeTax, _rub(12000000));
      expect(result.tax, _rub(1560000));
      expect(result.totalAfterTax, _rub(10440000));
    });

    test('one payment is the whole month', () {
      final result = _calculate(_caseA());

      expect(result.payments, [_rub(10440000)]);
    });

    test('two payments split the month by working days', () {
      final result = _calculate(_caseA(mode: PaymentMode.twoPayments));

      expect(result.payments, [_rub(4350000), _rub(6090000)]);
      expect(result.totalAfterTax, _rub(10440000));
    });
  });

  group('Case B (rounds to the kopeck)', () {
    test('rounds each line on its own, from the rounded lines before it', () {
      final result = _calculate(_caseB());

      expect(result.foodAllowance, _rub(724500)); // 7,245.00
      expect(result.extraHoursPay, _rub(823042)); // 8,230.4167 -> 8,230.42
      expect(result.incomeBeforeTax, _rub(11424042)); // 114,240.42
      expect(result.tax, _rub(1485125)); // 14,851.2546 -> 14,851.25
      expect(result.totalAfterTax, _rub(9938917)); // 99,389.17
    });

    test('one payment is the whole month', () {
      final result = _calculate(_caseB());

      expect(result.payments, [_rub(9938917)]);
    });

    test('two payments: the first is rounded, the second is the rest', () {
      final result = _calculate(_caseB(mode: PaymentMode.twoPayments));

      // 36,825.2357 -> 36,825.24; 99,389.17 - 36,825.24 = 62,563.93.
      expect(result.payments, [_rub(3682524), _rub(6256393)]);
    });

    test('the lines are the same however the month is paid', () {
      final one = _calculate(_caseB());
      final two = _calculate(_caseB(mode: PaymentMode.twoPayments));

      expect(two.foodAllowance, one.foodAllowance);
      expect(two.extraHoursPay, one.extraHoursPay);
      expect(two.incomeBeforeTax, one.incomeBeforeTax);
      expect(two.tax, one.tax);
      expect(two.totalAfterTax, one.totalAfterTax);
    });
  });

  group('rounding', () {
    SalaryInputs smallBase({required int baseKopecks}) {
      return SalaryInputs(
        baseSalary: _rub(baseKopecks),
        foodPerDay: _rub(0),
        workingDaysInMonth: 20,
        workingHoursInMonth: 4,
        extraHoursHundredths: 100, // one extra hour
        taxRateBasisPoints: 0,
      );
    }

    test('half a kopeck rounds up', () {
      // 2 * 0.05 / 4 * 1 hour is exactly 2.5 kopecks.
      expect(_calculate(smallBase(baseKopecks: 5)).extraHoursPay, _rub(3));
    });

    test('less than half a kopeck rounds down', () {
      final inputs = SalaryInputs(
        baseSalary: _rub(1),
        foodPerDay: _rub(0),
        workingDaysInMonth: 20,
        workingHoursInMonth: 8, // 2 * 0.01 / 8 * 1 hour is 0.25 kopeck
        extraHoursHundredths: 100,
        taxRateBasisPoints: 0,
      );

      expect(_calculate(inputs).extraHoursPay, _rub(0));
    });

    test('a tax of exactly half a kopeck rounds up', () {
      final inputs = SalaryInputs(
        baseSalary: _rub(5), // 0.05 ₽ at 50 % tax is 2.5 kopecks
        foodPerDay: _rub(0),
        workingDaysInMonth: 20,
        workingHoursInMonth: 160,
        extraHoursHundredths: 0,
        taxRateBasisPoints: 5000,
      );

      final result = _calculate(inputs);

      expect(result.tax, _rub(3));
      expect(result.totalAfterTax, _rub(2));
    });

    test('fractional extra hours and tax rates are exact', () {
      final inputs = SalaryInputs(
        baseSalary: _rub(10000000),
        foodPerDay: _rub(0),
        workingDaysInMonth: 20,
        workingHoursInMonth: 160,
        extraHoursHundredths: 750, // 7.5 hours
        taxRateBasisPoints: 1350, // 13.5 %
      );

      final result = _calculate(inputs);

      expect(result.extraHoursPay, _rub(937500)); // 9,375.00
      expect(result.incomeBeforeTax, _rub(10937500));
      expect(result.tax, _rub(1476563)); // 14,765.625 -> 14,765.63
      expect(result.totalAfterTax, _rub(9460937));
    });
  });

  group('edge cases', () {
    test('no extra hours means no extra pay', () {
      final inputs = SalaryInputs(
        baseSalary: _rub(10000000),
        foodPerDay: _rub(50000),
        workingDaysInMonth: 20,
        workingHoursInMonth: 160,
        extraHoursHundredths: 0,
        taxRateBasisPoints: 1300,
      );

      expect(_calculate(inputs).extraHoursPay, _rub(0));
    });

    test('no tax rate means no tax', () {
      final inputs = SalaryInputs(
        baseSalary: _rub(10000000),
        foodPerDay: _rub(0),
        workingDaysInMonth: 20,
        workingHoursInMonth: 160,
        extraHoursHundredths: 0,
        taxRateBasisPoints: 0,
        paymentMode: PaymentMode.twoPayments,
        workingDaysFirstHalf: 10,
      );

      final result = _calculate(inputs);

      expect(result.tax, _rub(0));
      expect(result.payments, [_rub(5000000), _rub(5000000)]);
    });

    test(
      'working every day of the first half leaves the rest to the second',
      () {
        final inputs = SalaryInputs(
          baseSalary: _rub(10000000),
          foodPerDay: _rub(50000),
          workingDaysInMonth: 20,
          workingDaysFirstHalf: 20,
          workingHoursInMonth: 160,
          extraHoursHundredths: 0,
          taxRateBasisPoints: 1300,
          paymentMode: PaymentMode.twoPayments,
        );

        final result = _calculate(inputs);

        // The taxed base 87,000.00 is paid first; food (net of tax) follows.
        expect(result.payments, [_rub(8700000), _rub(870000)]);
      },
    );

    test('rounding never makes the second payment negative', () {
      // Tax 2.5 kopecks rounds up to 3, leaving 2 of 5; the first share of
      // 2.5 kopecks would round up to 3, a kopeck more than is left to pay.
      final inputs = SalaryInputs(
        baseSalary: _rub(5),
        foodPerDay: _rub(0),
        workingDaysInMonth: 20,
        workingDaysFirstHalf: 20,
        workingHoursInMonth: 160,
        extraHoursHundredths: 0,
        taxRateBasisPoints: 5000,
        paymentMode: PaymentMode.twoPayments,
      );

      final result = _calculate(inputs);

      expect(result.totalAfterTax, _rub(2));
      expect(result.payments, [_rub(2), _rub(0)]);
    });

    test('no working day in the first half pays it nothing', () {
      final inputs = SalaryInputs(
        baseSalary: _rub(10000000),
        foodPerDay: _rub(50000),
        workingDaysInMonth: 20,
        workingHoursInMonth: 160,
        extraHoursHundredths: 0,
        taxRateBasisPoints: 1300,
        paymentMode: PaymentMode.twoPayments,
      );

      final result = _calculate(inputs);

      expect(result.payments.first, _rub(0));
      expect(result.payments.last, result.totalAfterTax);
    });

    test('the first-half days are ignored when paid in one payment', () {
      final inputs = SalaryInputs(
        baseSalary: _rub(10000000),
        foodPerDay: _rub(50000),
        workingDaysInMonth: 20,
        workingDaysFirstHalf: 99,
        workingHoursInMonth: 160,
        extraHoursHundredths: 0,
        taxRateBasisPoints: 1300,
      );

      expect(_calculate(inputs).payments, hasLength(1));
    });

    test('the payments list cannot be changed', () {
      final result = _calculate(_caseA());

      expect(() => result.payments.add(_rub(1)), throwsUnsupportedError);
    });

    test('works in another currency', () {
      final inputs = SalaryInputs(
        baseSalary: const Money(1000000, Currency.usd),
        foodPerDay: const Money(1000, Currency.usd),
        workingDaysInMonth: 20,
        workingHoursInMonth: 160,
        extraHoursHundredths: 0,
        taxRateBasisPoints: 1000,
      );

      final result = _calculate(inputs);

      expect(result.totalAfterTax, const Money(918000, Currency.usd));
    });
  });

  group('the figures always add up to the kopeck', () {
    test('for a spread of inputs, in both payment modes', () {
      var checked = 0;
      for (final base in [9876500, 10000001, 12345678, 777777]) {
        for (final days in [19, 21, 22, 23]) {
          for (final firstHalf in [0, 5, 9, 11, days]) {
            for (final hours in [152, 168, 176]) {
              for (final extra in [0, 50, 700, 1550]) {
                for (final rate in [0, 1300, 1350, 2275]) {
                  for (final mode in PaymentMode.values) {
                    final result = _calculate(
                      SalaryInputs(
                        baseSalary: _rub(base),
                        foodPerDay: _rub(39050),
                        workingDaysInMonth: days,
                        workingDaysFirstHalf: firstHalf,
                        workingHoursInMonth: hours,
                        extraHoursHundredths: extra,
                        taxRateBasisPoints: rate,
                        paymentMode: mode,
                      ),
                    );

                    expect(
                      result.incomeBeforeTax,
                      _rub(base) + result.foodAllowance + result.extraHoursPay,
                    );
                    expect(
                      result.totalAfterTax,
                      result.incomeBeforeTax - result.tax,
                    );
                    expect(
                      result.payments.fold(_rub(0), (sum, p) => sum + p),
                      result.totalAfterTax,
                    );
                    expect(
                      result.payments,
                      hasLength(mode == PaymentMode.onePayment ? 1 : 2),
                    );
                    expect(result.payments.any((p) => p.isNegative), isFalse);
                    checked++;
                  }
                }
              }
            }
          }
        }
      }
      expect(checked, greaterThan(1000));
    });
  });

  group('rejected inputs', () {
    SalaryInputs inputs({
      int base = 10000000,
      int food = 50000,
      int days = 20,
      int firstHalf = 10,
      int hours = 160,
      int extra = 0,
      int rate = 1300,
      PaymentMode mode = PaymentMode.onePayment,
    }) {
      return SalaryInputs(
        baseSalary: _rub(base),
        foodPerDay: _rub(food),
        workingDaysInMonth: days,
        workingDaysFirstHalf: firstHalf,
        workingHoursInMonth: hours,
        extraHoursHundredths: extra,
        taxRateBasisPoints: rate,
        paymentMode: mode,
      );
    }

    test('a valid set has no problems', () {
      expect(inputs().problems, isEmpty);
    });

    test('a base salary of zero or less', () {
      expect(_problemsOf(inputs(base: 0)), {
        SalaryInputProblem.baseSalaryNotPositive,
      });
      expect(_problemsOf(inputs(base: -1)), {
        SalaryInputProblem.baseSalaryNotPositive,
      });
    });

    test('a negative food allowance', () {
      expect(_problemsOf(inputs(food: -1)), {
        SalaryInputProblem.foodPerDayNegative,
      });
    });

    test('working days outside 1 to 31', () {
      const problem = {SalaryInputProblem.workingDaysOutOfRange};
      expect(_problemsOf(inputs(days: 0, firstHalf: 0)), problem);
      expect(_problemsOf(inputs(days: 32)), problem);
      expect(inputs(days: 31).problems, isEmpty);
    });

    test('first-half days outside the month, only when paid in two', () {
      const problem = {SalaryInputProblem.firstHalfDaysOutOfRange};
      expect(
        _problemsOf(inputs(firstHalf: 21, mode: PaymentMode.twoPayments)),
        problem,
      );
      expect(
        _problemsOf(inputs(firstHalf: -1, mode: PaymentMode.twoPayments)),
        problem,
      );
      expect(inputs(firstHalf: 21).problems, isEmpty);
    });

    test('working hours of zero or less', () {
      expect(_problemsOf(inputs(hours: 0)), {
        SalaryInputProblem.workingHoursNotPositive,
      });
    });

    test('negative extra hours', () {
      expect(_problemsOf(inputs(extra: -100)), {
        SalaryInputProblem.extraHoursNegative,
      });
    });

    test('a tax rate outside 0 to 100 %', () {
      const problem = {SalaryInputProblem.taxRateOutOfRange};
      expect(_problemsOf(inputs(rate: -1)), problem);
      expect(_problemsOf(inputs(rate: 10001)), problem);
      expect(inputs(rate: 10000).problems, isEmpty);
    });

    test('reports every problem at once', () {
      expect(_problemsOf(inputs(base: 0, hours: 0, extra: -1, rate: 20000)), {
        SalaryInputProblem.baseSalaryNotPositive,
        SalaryInputProblem.workingHoursNotPositive,
        SalaryInputProblem.extraHoursNegative,
        SalaryInputProblem.taxRateOutOfRange,
      });
    });
  });
}
