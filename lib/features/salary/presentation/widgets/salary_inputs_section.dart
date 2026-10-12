import 'package:flutter/material.dart';
import 'package:money_scribe/core/formatting/decimal_input_formatter.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/widgets/amount_field.dart';
import 'package:money_scribe/core/widgets/app_text_field.dart';
import 'package:money_scribe/features/salary/domain/salary_form.dart';

/// The "Inputs" section of the Salary screen: the choice of one or two
/// payments and the numbers the month is calculated from.
///
/// The text fields start from [form] when the section is built, and keep what
/// is typed after that, so give it a new key when the form is replaced.
class SalaryInputsSection extends StatefulWidget {
  const new({
    required this.form,
    required this.onFieldChanged,
    required this.onPaymentModeSelected,
    super.key,
  });

  final SalaryForm form;
  final void Function(SalaryField field, String value) onFieldChanged;
  final ValueChanged<PaymentMode> onPaymentModeSelected;

  @override
  State<SalaryInputsSection> createState() => _SalaryInputsSectionState();
}

class _SalaryInputsSectionState extends State<SalaryInputsSection> {
  late final Map<SalaryField, TextEditingController> _controllers = {
    for (final field in SalaryField.values)
      field: TextEditingController(text: widget.form.valueOf(field)),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final form = widget.form;
    final isTwoPayments = form.paymentMode == PaymentMode.twoPayments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.salaryInputsTitle,
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 12),
        Text(l10n.paymentsPerMonthLabel, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        SegmentedButton<PaymentMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: PaymentMode.onePayment,
              label: Text(l10n.onePaymentOption),
            ),
            ButtonSegment(
              value: PaymentMode.twoPayments,
              label: Text(l10n.twoPaymentsOption),
            ),
          ],
          selected: {form.paymentMode},
          onSelectionChanged: (selection) =>
              widget.onPaymentModeSelected(selection.first),
        ),
        const SizedBox(height: 16),
        _amountField(SalaryField.baseSalary, l10n.baseSalaryLabel),
        if (isTwoPayments) ...[
          const SizedBox(height: 16),
          _countField(
            SalaryField.workingDaysFirstHalf,
            l10n.workingDaysFirstHalfLabel,
          ),
        ],
        const SizedBox(height: 16),
        _countField(
          SalaryField.workingDaysInMonth,
          l10n.workingDaysInMonthLabel,
        ),
        const SizedBox(height: 16),
        _amountField(SalaryField.foodPerDay, l10n.foodPerDayLabel),
        const SizedBox(height: 16),
        _countField(
          SalaryField.workingHoursInMonth,
          l10n.workingHoursInMonthLabel,
        ),
        const SizedBox(height: 16),
        _decimalField(SalaryField.extraHours, l10n.extraHoursLabel),
        const SizedBox(height: 16),
        _decimalField(SalaryField.taxRate, l10n.taxRateLabel, suffix: '%'),
        if (isTwoPayments) ...[
          const SizedBox(height: 16),
          Text(
            l10n.firstPaymentPaidOnDay(day: form.firstPayDay),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.secondPaymentPaidOnDay(day: form.secondPayDay),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _amountField(SalaryField field, String label) {
    return AmountField(
      controller: _controllers[field]!,
      label: label,
      currency: widget.form.currency,
      hintText: '0',
      alwaysFloatLabel: true,
      errorText: _errorText(field),
      textInputAction: TextInputAction.next,
      onChanged: (value) => widget.onFieldChanged(field, value),
    );
  }

  Widget _countField(SalaryField field, String label) {
    return AppTextField(
      controller: _controllers[field]!,
      label: label,
      hintText: '0',
      alwaysFloatLabel: true,
      errorText: _errorText(field),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.end,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: const [DecimalInputFormatter()],
      onChanged: (value) => widget.onFieldChanged(field, value),
    );
  }

  Widget _decimalField(SalaryField field, String label, {String? suffix}) {
    return AppTextField(
      controller: _controllers[field]!,
      label: label,
      hintText: '0',
      alwaysFloatLabel: true,
      unit: suffix,
      errorText: _errorText(field),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.end,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      inputFormatters: const [DecimalInputFormatter(maxFractionDigits: 2)],
      onChanged: (value) => widget.onFieldChanged(field, value),
    );
  }

  String? _errorText(SalaryField field) {
    final error = widget.form.errorOf(field);
    if (error == null) return null;
    final l10n = context.l10n;

    return switch ((field, error)) {
      (
        SalaryField.baseSalary || SalaryField.foodPerDay,
        SalaryFieldError.invalid,
      ) =>
        l10n.fieldInvalidAmount,
      (_, SalaryFieldError.invalid) => l10n.fieldInvalidNumber,
      (SalaryField.baseSalary, SalaryFieldError.outOfRange) ||
      (
        SalaryField.workingHoursInMonth,
        SalaryFieldError.outOfRange,
      ) => l10n.fieldMustBePositive,
      (SalaryField.workingDaysInMonth, SalaryFieldError.outOfRange) =>
        l10n.workingDaysRange,
      (SalaryField.workingDaysFirstHalf, SalaryFieldError.outOfRange) =>
        l10n.firstHalfDaysRange,
      (SalaryField.taxRate, SalaryFieldError.outOfRange) => l10n.taxRateRange,
      // The remaining fields cannot be out of range: their typed text cannot
      // be negative.
      (_, SalaryFieldError.outOfRange) => l10n.fieldInvalidNumber,
    };
  }
}
