import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/salary/domain/salary_calculator.dart';
import 'package:money_scribe/features/salary/domain/salary_defaults.dart';
import 'package:money_scribe/features/salary/domain/salary_form.dart';
import 'package:money_scribe/features/salary/domain/salary_inputs.dart';
import 'package:money_scribe/features/salary/domain/salary_month.dart';

Money _rub(int kopecks) => Money(kopecks, Currency.rub);

/// Invented numbers: the same as the exact case of the calculation tests.
SalaryForm _filled({PaymentMode mode = PaymentMode.onePayment}) {
  return SalaryForm(
    baseSalary: '100000',
    workingDaysInMonth: '20',
    workingDaysFirstHalf: '10',
    foodPerDay: '500',
    workingHoursInMonth: '160',
    extraHours: '8',
    paymentMode: mode,
  );
}

void main() {
  group('a new month', () {
    test('is empty, with the usual tax rate and the account schedule', () {
      final form = SalaryForm.empty(
        const SalaryDefaults(
          paymentMode: PaymentMode.twoPayments,
          firstPayDay: 15,
          secondPayDay: 3,
        ),
      );

      expect(form.baseSalary, isEmpty);
      expect(form.taxRate, '13');
      expect(form.paymentMode, PaymentMode.twoPayments);
      expect(form.firstPayDay, 15);
      expect(form.secondPayDay, 3);
      expect(form.inputs, isNull);
    });
  });

  group('inputs', () {
    test('turn a complete form into the numbers to calculate', () {
      final inputs = _filled().inputs!;

      expect(inputs.baseSalary, _rub(10000000));
      expect(inputs.foodPerDay, _rub(50000));
      expect(inputs.workingDaysInMonth, 20);
      expect(inputs.workingHoursInMonth, 160);
      expect(inputs.extraHoursHundredths, 800);
      expect(inputs.taxRateBasisPoints, 1300);
      expect(inputs.paymentMode, PaymentMode.onePayment);
    });

    test('calculate to the exact case of the model', () {
      final calculation = SalaryCalculator.calculate(_filled().inputs!);

      expect(
        (calculation as SalaryComputed).result.totalAfterTax,
        _rub(10440000),
      );
    });

    test('are missing while a required number is empty', () {
      for (final field in [
        SalaryField.baseSalary,
        SalaryField.workingDaysInMonth,
        SalaryField.workingHoursInMonth,
        SalaryField.taxRate,
      ]) {
        expect(_filled().withField(field, '').inputs, isNull, reason: '$field');
      }
    });

    test('are missing while a number cannot be read', () {
      expect(_filled().withField(SalaryField.baseSalary, '1a').inputs, isNull);
      expect(_filled().withField(SalaryField.taxRate, '1.234').inputs, isNull);
    });

    test('treat an empty food allowance and empty extra hours as none', () {
      final inputs = _filled()
          .withField(SalaryField.foodPerDay, '')
          .withField(SalaryField.extraHours, '')
          .inputs!;

      expect(inputs.foodPerDay, _rub(0));
      expect(inputs.extraHoursHundredths, 0);
    });

    test('need the first-half days only for two payments', () {
      final noFirstHalf = _filled().withField(
        SalaryField.workingDaysFirstHalf,
        '',
      );

      expect(noFirstHalf.inputs, isNotNull);
      expect(
        noFirstHalf.withPaymentMode(PaymentMode.twoPayments).inputs,
        isNull,
      );
    });

    test('keep fractions of hours and of the tax rate exact', () {
      final inputs = _filled()
          .withField(SalaryField.extraHours, '7.5')
          .withField(SalaryField.taxRate, '13,5')
          .inputs!;

      expect(inputs.extraHoursHundredths, 750);
      expect(inputs.taxRateBasisPoints, 1350);
    });
  });

  group('errors', () {
    test('an empty field is not an error', () {
      for (final field in SalaryField.values) {
        expect(const SalaryForm().errorOf(field), isNull, reason: '$field');
      }
    });

    test('a valid form has none', () {
      for (final field in SalaryField.values) {
        expect(_filled().errorOf(field), isNull, reason: '$field');
      }
    });

    test('a number that cannot be read is invalid', () {
      expect(
        _filled()
            .withField(SalaryField.baseSalary, '1.234')
            .errorOf(SalaryField.baseSalary),
        SalaryFieldError.invalid,
      );
      expect(
        _filled()
            .withField(SalaryField.workingDaysInMonth, '1.5')
            .errorOf(SalaryField.workingDaysInMonth),
        SalaryFieldError.invalid,
      );
    });

    test('numbers outside what a field allows are out of range', () {
      SalaryFieldError? error(SalaryField field, String text) =>
          _filled().withField(field, text).errorOf(field);

      expect(error(SalaryField.baseSalary, '0'), SalaryFieldError.outOfRange);
      expect(
        error(SalaryField.workingDaysInMonth, '0'),
        SalaryFieldError.outOfRange,
      );
      expect(
        error(SalaryField.workingDaysInMonth, '32'),
        SalaryFieldError.outOfRange,
      );
      expect(
        error(SalaryField.workingHoursInMonth, '0'),
        SalaryFieldError.outOfRange,
      );
      expect(error(SalaryField.taxRate, '100.01'), SalaryFieldError.outOfRange);
      expect(error(SalaryField.taxRate, '100'), isNull);
    });

    test('first-half days cannot be more than the days of the month', () {
      final form = _filled(mode: PaymentMode.twoPayments)
          .withField(SalaryField.workingDaysFirstHalf, '21');

      expect(
        form.errorOf(SalaryField.workingDaysFirstHalf),
        SalaryFieldError.outOfRange,
      );
    });

    test('first-half days are not checked for one payment', () {
      final form = _filled().withField(SalaryField.workingDaysFirstHalf, '99');

      expect(form.errorOf(SalaryField.workingDaysFirstHalf), isNull);
    });
  });

  group('a saved month', () {
    final saved = SalaryMonth(
      month: const YearMonth(2026, 10),
      inputs: SalaryInputs(
        baseSalary: _rub(10000000),
        foodPerDay: _rub(50000),
        workingDaysInMonth: 20,
        workingDaysFirstHalf: 10,
        workingHoursInMonth: 160,
        extraHoursHundredths: 750,
        taxRateBasisPoints: 1350,
        paymentMode: PaymentMode.twoPayments,
      ),
      firstPayDay: 18,
      secondPayDay: 4,
    );

    test('becomes a form that shows its numbers', () {
      final form = SalaryForm.fromMonth(saved);

      expect(form.baseSalary, '100000.00');
      expect(form.foodPerDay, '500.00');
      expect(form.workingDaysInMonth, '20');
      expect(form.workingDaysFirstHalf, '10');
      expect(form.workingHoursInMonth, '160');
      expect(form.extraHours, '7.5');
      expect(form.taxRate, '13.5');
      expect(form.paymentMode, PaymentMode.twoPayments);
      expect(form.firstPayDay, 18);
    });

    test('comes back unchanged through the form', () {
      expect(SalaryForm.fromMonth(saved).toMonth(saved.month), saved);
    });

    test('cannot be made from an incomplete form', () {
      expect(const SalaryForm().toMonth(saved.month), isNull);
    });
  });
}
