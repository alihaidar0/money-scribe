import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/formatting/decimal_text.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/salary/domain/salary_defaults.dart';
import 'package:money_scribe/features/salary/domain/salary_inputs.dart';
import 'package:money_scribe/features/salary/domain/salary_month.dart';

/// The numbers a person types on the Salary screen.
enum SalaryField {
  baseSalary,
  workingDaysInMonth,
  workingDaysFirstHalf,
  foodPerDay,
  workingHoursInMonth,
  extraHours,
  taxRate,
}

/// What is wrong with a typed number.
enum SalaryFieldError {
  /// It is not a number the field can read.
  invalid,

  /// It is a number, but outside what the field allows.
  outOfRange,
}

/// The Salary form as typed: every number is text until it is complete and
/// valid, so a half-typed `12.` never loses what the person meant. [inputs]
/// turns it into [SalaryInputs] once it can be calculated.
///
/// The food allowance and the extra hours may be left empty, which means none.
/// Everything else is required.
final class SalaryForm extends Equatable {
  const new({
    this.baseSalary = '',
    this.workingDaysInMonth = '',
    this.workingDaysFirstHalf = '',
    this.foodPerDay = '',
    this.workingHoursInMonth = '',
    this.extraHours = '',
    this.taxRate = defaultTaxRate,
    this.paymentMode = PaymentMode.onePayment,
    this.firstPayDay = 20,
    this.secondPayDay = 5,
    this.currency = Currency.rub,
  });

  /// A new month that starts the way [defaults] say: paid the same way, with
  /// the figures that rarely change from month to month already typed.
  new empty(SalaryDefaults defaults)
    : this(
        baseSalary: defaults.baseSalary?.toDecimalString() ?? '',
        foodPerDay: defaults.foodPerDay?.toDecimalString() ?? '',
        workingHoursInMonth: '${defaults.workingHoursInMonth ?? ''}',
        taxRate: DecimalText.formatHundredths(defaults.taxRateBasisPoints),
        paymentMode: defaults.paymentMode,
        firstPayDay: defaults.firstPayDay,
        secondPayDay: defaults.secondPayDay,
        currency: defaults.currency,
      );

  /// The form of a saved month.
  new fromMonth(SalaryMonth saved)
    : this(
        baseSalary: saved.inputs.baseSalary.toDecimalString(),
        workingDaysInMonth: '${saved.inputs.workingDaysInMonth}',
        workingDaysFirstHalf: saved.inputs.workingDaysFirstHalf == 0
            ? ''
            : '${saved.inputs.workingDaysFirstHalf}',
        foodPerDay: saved.inputs.foodPerDay.toDecimalString(),
        workingHoursInMonth: '${saved.inputs.workingHoursInMonth}',
        extraHours: DecimalText.formatHundredths(
          saved.inputs.extraHoursHundredths,
        ),
        taxRate: DecimalText.formatHundredths(saved.inputs.taxRateBasisPoints),
        paymentMode: saved.inputs.paymentMode,
        firstPayDay: saved.firstPayDay,
        secondPayDay: saved.secondPayDay,
        currency: saved.inputs.baseSalary.currency,
      );

  /// The tax rate a new month starts with, in percent.
  static const defaultTaxRate = '13';

  final String baseSalary;
  final String workingDaysInMonth;

  /// Working days from the 1st to the 15th; asked for only when the month is
  /// paid in two payments.
  final String workingDaysFirstHalf;
  final String foodPerDay;
  final String workingHoursInMonth;

  /// Extra hours, such as `8` or `7.5`.
  final String extraHours;

  /// The tax rate in percent, such as `13` or `13.5`.
  final String taxRate;

  final PaymentMode paymentMode;
  final int firstPayDay;
  final int secondPayDay;
  final Currency currency;

  String valueOf(SalaryField field) {
    return switch (field) {
      SalaryField.baseSalary => baseSalary,
      SalaryField.workingDaysInMonth => workingDaysInMonth,
      SalaryField.workingDaysFirstHalf => workingDaysFirstHalf,
      SalaryField.foodPerDay => foodPerDay,
      SalaryField.workingHoursInMonth => workingHoursInMonth,
      SalaryField.extraHours => extraHours,
      SalaryField.taxRate => taxRate,
    };
  }

  SalaryForm withField(SalaryField field, String value) {
    return switch (field) {
      SalaryField.baseSalary => _copy(baseSalary: value),
      SalaryField.workingDaysInMonth => _copy(workingDaysInMonth: value),
      SalaryField.workingDaysFirstHalf => _copy(workingDaysFirstHalf: value),
      SalaryField.foodPerDay => _copy(foodPerDay: value),
      SalaryField.workingHoursInMonth => _copy(workingHoursInMonth: value),
      SalaryField.extraHours => _copy(extraHours: value),
      SalaryField.taxRate => _copy(taxRate: value),
    };
  }

  SalaryForm withPaymentMode(PaymentMode mode) => _copy(paymentMode: mode);

  /// What is wrong with [field], or `null` when it is empty or fine. An empty
  /// field is not an error: the form just cannot be calculated yet.
  SalaryFieldError? errorOf(SalaryField field) {
    if (valueOf(field).trim().isEmpty) return null;
    return switch (field) {
      SalaryField.baseSalary => _amountError(
        baseSalary,
        isAllowed: (money) => money.isPositive,
      ),
      SalaryField.foodPerDay => _amountError(
        foodPerDay,
        isAllowed: (money) => !money.isNegative,
      ),
      SalaryField.workingDaysInMonth => _countError(
        workingDaysInMonth,
        isAllowed: (days) => days >= 1 && days <= SalaryInputs.maxWorkingDays,
      ),
      SalaryField.workingDaysFirstHalf =>
        paymentMode == PaymentMode.twoPayments
            ? _countError(
                workingDaysFirstHalf,
                isAllowed: (days) {
                  final month = DecimalText.parseCount(workingDaysInMonth);
                  return month == null || days <= month;
                },
              )
            : null,
      SalaryField.workingHoursInMonth => _countError(
        workingHoursInMonth,
        isAllowed: (hours) => hours >= 1,
      ),
      SalaryField.extraHours =>
        DecimalText.parseHundredths(extraHours) == null
            ? SalaryFieldError.invalid
            : null,
      SalaryField.taxRate => _hundredthsError(
        taxRate,
        isAllowed: (rate) => rate <= SalaryInputs.fullTaxRate,
      ),
    };
  }

  /// The form as [SalaryInputs], or `null` while a required number is missing
  /// or cannot be read. The inputs may still be out of range; the calculator
  /// says so.
  SalaryInputs? get inputs {
    final base = Money.tryParse(baseSalary, currency);
    final food = foodPerDay.trim().isEmpty
        ? Money.zero(currency)
        : Money.tryParse(foodPerDay, currency);
    final days = DecimalText.parseCount(workingDaysInMonth);
    final hours = DecimalText.parseCount(workingHoursInMonth);
    final extra = extraHours.trim().isEmpty
        ? 0
        : DecimalText.parseHundredths(extraHours);
    final rate = DecimalText.parseHundredths(taxRate);
    final firstHalf = paymentMode == PaymentMode.twoPayments
        ? DecimalText.parseCount(workingDaysFirstHalf)
        : DecimalText.parseCount(workingDaysFirstHalf) ?? 0;

    if (base == null ||
        food == null ||
        days == null ||
        hours == null ||
        extra == null ||
        rate == null ||
        firstHalf == null) {
      return null;
    }
    return SalaryInputs(
      baseSalary: base,
      foodPerDay: food,
      workingDaysInMonth: days,
      workingDaysFirstHalf: firstHalf,
      workingHoursInMonth: hours,
      extraHoursHundredths: extra,
      taxRateBasisPoints: rate,
      paymentMode: paymentMode,
    );
  }

  /// This form as the saved [month], or `null` while it cannot be calculated.
  /// [version] is the version of the saved month this edits, `null` for a new
  /// one.
  SalaryMonth? toMonth(YearMonth month, {int? version}) {
    final inputs = this.inputs;
    if (inputs == null) return null;
    return SalaryMonth(
      month: month,
      inputs: inputs,
      firstPayDay: firstPayDay,
      secondPayDay: secondPayDay,
      version: version,
    );
  }

  SalaryFieldError? _amountError(
    String text, {
    required bool Function(Money) isAllowed,
  }) {
    final money = Money.tryParse(text, currency);
    if (money == null) return SalaryFieldError.invalid;
    return isAllowed(money) ? null : SalaryFieldError.outOfRange;
  }

  SalaryFieldError? _countError(
    String text, {
    required bool Function(int) isAllowed,
  }) {
    final count = DecimalText.parseCount(text);
    if (count == null) return SalaryFieldError.invalid;
    return isAllowed(count) ? null : SalaryFieldError.outOfRange;
  }

  SalaryFieldError? _hundredthsError(
    String text, {
    required bool Function(int) isAllowed,
  }) {
    final value = DecimalText.parseHundredths(text);
    if (value == null) return SalaryFieldError.invalid;
    return isAllowed(value) ? null : SalaryFieldError.outOfRange;
  }

  SalaryForm _copy({
    String? baseSalary,
    String? workingDaysInMonth,
    String? workingDaysFirstHalf,
    String? foodPerDay,
    String? workingHoursInMonth,
    String? extraHours,
    String? taxRate,
    PaymentMode? paymentMode,
  }) {
    return SalaryForm(
      baseSalary: baseSalary ?? this.baseSalary,
      workingDaysInMonth: workingDaysInMonth ?? this.workingDaysInMonth,
      workingDaysFirstHalf: workingDaysFirstHalf ?? this.workingDaysFirstHalf,
      foodPerDay: foodPerDay ?? this.foodPerDay,
      workingHoursInMonth: workingHoursInMonth ?? this.workingHoursInMonth,
      extraHours: extraHours ?? this.extraHours,
      taxRate: taxRate ?? this.taxRate,
      paymentMode: paymentMode ?? this.paymentMode,
      firstPayDay: firstPayDay,
      secondPayDay: secondPayDay,
      currency: currency,
    );
  }

  @override
  List<Object> get props => [
    baseSalary,
    workingDaysInMonth,
    workingDaysFirstHalf,
    foodPerDay,
    workingHoursInMonth,
    extraHours,
    taxRate,
    paymentMode,
    firstPayDay,
    secondPayDay,
    currency,
  ];
}
