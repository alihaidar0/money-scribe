import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/bar_clearance.dart';
import 'package:money_scribe/core/widgets/button_spinner.dart';
import 'package:money_scribe/core/widgets/failure_snack_bar.dart';
import 'package:money_scribe/core/widgets/hero_card.dart';
import 'package:money_scribe/core/widgets/month_chip.dart';
import 'package:money_scribe/core/widgets/month_picker_sheet.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/core/widgets/success_snack_bar.dart';
import 'package:money_scribe/core/widgets/wide_frame.dart';
import 'package:money_scribe/features/salary/bloc/salary_bloc.dart';
import 'package:money_scribe/features/salary/domain/salary_form.dart';
import 'package:money_scribe/features/salary/domain/salary_result.dart';
import 'package:money_scribe/features/salary/presentation/widgets/salary_inputs_section.dart';
import 'package:money_scribe/features/salary/presentation/widgets/salary_results_section.dart';
import 'package:money_scribe/features/salary/presentation/widgets/salary_section_switch.dart';
import 'package:money_scribe/features/salary/presentation/widgets/switch_payment_mode_dialog.dart';

/// The content of the Salary screen, in the Salary tab and when a saved month
/// is opened from the history: the states, the month, the total, the results,
/// the inputs and the pinned save button. It needs a [SalaryBloc] above it.
///
/// With [editing] it is a saved month opened to be corrected: no switch to the
/// fixed items, a month that cannot be changed, and "Save changes", which is
/// available only once something changed.
class SalaryBody extends StatelessWidget {
  const new({required this.editing, super.key});

  final bool editing;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SalaryBloc>();

    return BlocListener<SalaryBloc, SalaryState>(
      listenWhen: (previous, current) =>
          previous.saveStatus != current.saveStatus ||
          previous.deleteStatus != current.deleteStatus,
      listener: _onStatusChanged,
      child: BlocBuilder<SalaryBloc, SalaryState>(
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.formVersion != current.formVersion,
        builder: (context, state) => switch (state.status) {
          SalaryStatus.loading => const _SalarySkeleton(),
          SalaryStatus.noConnection => FailureView(
            kind: FailureKind.noConnection,
            onRetry: () => bloc.add(const SalaryRetried()),
          ),
          SalaryStatus.failure => FailureView(
            kind: FailureKind.error,
            errorTitle: context.l10n.salaryLoadFailed,
            onRetry: () => bloc.add(const SalaryRetried()),
          ),
          SalaryStatus.ready => _SalaryContent(editing: editing),
        },
      ),
    );
  }

  void _onStatusChanged(BuildContext context, SalaryState state) {
    final l10n = context.l10n;
    final bloc = context.read<SalaryBloc>();

    switch (state.saveStatus) {
      case SalarySaveStatus.saved when !editing:
        showSuccessSnackBar(context, l10n.monthSaved);
      case SalarySaveStatus.failed:
        showFailureSnackBar(
          context,
          l10n.couldNotSave,
          onRetry: () => bloc.add(const SalarySaveRequested()),
        );
      case SalarySaveStatus.stale:
        showFailureSnackBar(
          context,
          l10n.monthChangedElsewhere,
          actionLabel: l10n.loadLatestAction,
          onRetry: () => bloc.add(const SalaryRetried()),
        );
      case SalarySaveStatus.idle ||
          SalarySaveStatus.saving ||
          SalarySaveStatus.saved:
        break;
    }

    switch (state.deleteStatus) {
      case SalaryDeleteStatus.failed:
        showFailureSnackBar(
          context,
          l10n.couldNotDelete,
          onRetry: () => bloc.add(const SalaryDeleteRequested()),
        );
      case SalaryDeleteStatus.stale:
        showFailureSnackBar(
          context,
          l10n.monthChangedElsewhere,
          actionLabel: l10n.loadLatestAction,
          onRetry: () => bloc.add(const SalaryRetried()),
        );
      case SalaryDeleteStatus.idle ||
          SalaryDeleteStatus.deleting ||
          SalaryDeleteStatus.deleted:
        break;
    }
  }
}

/// The content width from which the results and the inputs sit side by side.
const _twoColumnsFrom = 720.0;

class _SalaryContent extends StatelessWidget {
  const new({required this.editing});

  final bool editing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final summary = [
                if (!editing) ...[
                  SalarySectionSwitch(
                    selected: SalarySection.month,
                    month: context.select<SalaryBloc, YearMonth>(
                      (bloc) => bloc.state.month,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _MonthRow(editing: editing),
                const SizedBox(height: 16),
                const _Hero(),
                const SizedBox(height: 24),
                const _Results(),
              ];
              final inputs = [const _Inputs()];

              if (constraints.maxWidth >= _twoColumnsFrom) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: FrameWidth.wide.value,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: ListView(children: summary)),
                          const SizedBox(width: 24),
                          Expanded(child: ListView(children: inputs)),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16).withBarClearance(context),
                children: [...summary, const SizedBox(height: 24), ...inputs],
              );
            },
          ),
        ),
        _SaveBar(editing: editing),
      ],
    );
  }
}

class _MonthRow extends StatelessWidget {
  const new({required this.editing});

  final bool editing;

  @override
  Widget build(BuildContext context) {
    final month = context.select<SalaryBloc, YearMonth>(
      (bloc) => bloc.state.month,
    );

    return Align(
      alignment: AlignmentDirectional.centerStart,
      // A saved month opened to be corrected stays the month it is.
      child: MonthChip(
        month: month,
        onPressed: editing ? null : () => _choose(context, month),
      ),
    );
  }

  Future<void> _choose(BuildContext context, YearMonth month) async {
    final bloc = context.read<SalaryBloc>();
    final chosen = await showMonthPickerSheet(
      context,
      selected: month,
      last: YearMonth.fromDate(context.read<Clock>().now()),
    );
    if (chosen != null && chosen != month) {
      bloc.add(SalaryMonthSelected(chosen));
    }
  }
}

typedef _HeroFigures = (
  SalaryResult?,
  PaymentMode,
  Currency,
  YearMonth,
  int,
  int,
  Money?,
);

/// The total after tax, and for a month paid in two payments the pay of each
/// part and the day it is paid. It shows what the server calculated for a saved
/// month as it is, and what is calculated from the form once it is edited, with
/// the saved total beside it.
class _Hero extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatter = context.moneyFormatter;
    final months = context.monthFormatter;

    final state = context.select<SalaryBloc, _HeroFigures>(
      (bloc) => (
        bloc.state.shownResult,
        bloc.state.form.paymentMode,
        bloc.state.form.currency,
        bloc.state.month,
        bloc.state.form.firstPayDay,
        bloc.state.form.secondPayDay,
        bloc.state.savedTotalAfterTax,
      ),
    );
    final (
      result,
      mode,
      currency,
      month,
      firstPayDay,
      secondPayDay,
      savedTotal,
    ) = state;
    final zero = Money.zero(currency);
    final payments = result?.payments ?? [zero, zero];

    return HeroCard(
      label: l10n.salaryTotalAfterTax,
      stackedDetails: true,
      amount: formatter.format(result?.totalAfterTax ?? zero),
      details: [
        if (mode == PaymentMode.twoPayments) ...[
          HeroDetail(
            label: l10n.partPaidOn(
              part: l10n.partFirst,
              date: months.formatDay(month, firstPayDay),
            ),
            amount: formatter.format(payments.first),
          ),
          HeroDetail(
            label: l10n.partPaidOn(
              part: l10n.partSecond,
              date: months.formatDay(month.next, secondPayDay),
            ),
            amount: formatter.format(payments.last),
          ),
        ],
        if (savedTotal != null)
          HeroDetail(
            label: l10n.salarySavedTotalLabel,
            amount: formatter.format(savedTotal),
          ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final form = context.select<SalaryBloc, SalaryForm>(
      (bloc) => bloc.state.form,
    );
    final result = context.select<SalaryBloc, SalaryResult?>(
      (bloc) => bloc.state.shownResult,
    );

    return SalaryResultsSection(inputs: form.inputs, result: result);
  }
}

class _Inputs extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SalaryBloc>();
    final form = context.select<SalaryBloc, SalaryForm>(
      (bloc) => bloc.state.form,
    );
    final version = context.select<SalaryBloc, int>(
      (bloc) => bloc.state.formVersion,
    );

    return SalaryInputsSection(
      // A new key starts the text fields again when another month is loaded.
      key: ValueKey(version),
      form: form,
      onFieldChanged: (field, value) =>
          bloc.add(SalaryFieldChanged(field, value)),
      onPaymentModeSelected: (mode) => _selectMode(context, mode),
    );
  }

  Future<void> _selectMode(BuildContext context, PaymentMode mode) async {
    final bloc = context.read<SalaryBloc>();
    final state = bloc.state;
    if (mode == state.form.paymentMode) return;

    // A month that is saved changes how it is paid only after a confirmation;
    // a new one has nothing to lose.
    final confirmed =
        !state.isSaved ||
        await confirmPaymentModeSwitch(
          context,
          target: mode,
          month: state.month,
        );
    if (confirmed) bloc.add(SalaryPaymentModeSelected(mode));
  }
}

/// The pinned "Save month" or "Save changes" button, just above the
/// navigation bar or the bottom of the screen.
class _SaveBar extends StatelessWidget {
  const new({required this.editing});

  final bool editing;

  @override
  Widget build(BuildContext context) {
    final canSave = context.select<SalaryBloc, bool>(
      (bloc) => bloc.state.canSave && (!editing || bloc.state.isEdited),
    );
    final isSaving = context.select<SalaryBloc, bool>(
      (bloc) => bloc.state.saveStatus == SalarySaveStatus.saving,
    );
    final l10n = context.l10n;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: FrameWidth.regular.value),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canSave
                      ? () => context.read<SalaryBloc>().add(
                          const SalarySaveRequested(),
                        )
                      : null,
                  child: isSaving
                      ? const ButtonSpinner()
                      : Text(
                          editing
                              ? l10n.saveChangesAction
                              : l10n.saveMonthAction,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// SAL-12: grey blocks where the content will be.
class _SalarySkeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const SkeletonBox(height: 40, radius: 100),
          const SizedBox(height: 16),
          const SkeletonBox(height: 148),
          const SizedBox(height: 16),
          for (var i = 0; i < 6; i++) ...[
            const SkeletonBox(),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
