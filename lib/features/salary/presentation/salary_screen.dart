import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/button_spinner.dart';
import 'package:money_scribe/core/widgets/hero_card.dart';
import 'package:money_scribe/core/widgets/month_chip.dart';
import 'package:money_scribe/core/widgets/month_picker_sheet.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/core/widgets/top_level_screen.dart';
import 'package:money_scribe/features/salary/bloc/salary_bloc.dart';
import 'package:money_scribe/features/salary/domain/salary_form.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';
import 'package:money_scribe/features/salary/domain/salary_result.dart';
import 'package:money_scribe/features/salary/presentation/widgets/salary_history_button.dart';
import 'package:money_scribe/features/salary/presentation/widgets/salary_inputs_section.dart';
import 'package:money_scribe/features/salary/presentation/widgets/salary_results_section.dart';
import 'package:money_scribe/features/salary/presentation/widgets/salary_section_switch.dart';
import 'package:money_scribe/features/salary/presentation/widgets/switch_payment_mode_dialog.dart';

/// SAL-1, SAL-2, SAL-3, SAL-4, SAL-5, SAL-10 and their empty, loading, error
/// and no-connection states: the salary of a month, calculated as it is
/// typed, and saving it.
class SalaryScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SalaryBloc(
        repository: context.read<SalaryRepository>(),
        now: context.read<Clock>().now,
      )..add(const SalaryStarted()),
      child: const _SalaryView(),
    );
  }
}

class _SalaryView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SalaryBloc>();

    return BlocListener<SalaryBloc, SalaryState>(
      listenWhen: (previous, current) =>
          previous.saveStatus != current.saveStatus,
      listener: _onSaveStatusChanged,
      child: TopLevelScreen(
        title: context.l10n.salaryTitle,
        actions: const [SalaryHistoryButton()],
        body: BlocBuilder<SalaryBloc, SalaryState>(
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
            SalaryStatus.ready => const _SalaryContent(),
          },
        ),
      ),
    );
  }

  void _onSaveStatusChanged(BuildContext context, SalaryState state) {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;

    switch (state.saveStatus) {
      case SalarySaveStatus.saved:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l10n.monthSaved)),
                ],
              ),
              action: SnackBarAction(
                label: l10n.viewHistoryAction,
                onPressed: () => context.push(AppRoutes.salaryHistory),
              ),
            ),
          );
      case SalarySaveStatus.failed:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: colors.errorContainer,
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: colors.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.couldNotSave,
                      style: TextStyle(color: colors.onErrorContainer),
                    ),
                  ),
                ],
              ),
              action: SnackBarAction(
                label: l10n.retryAction,
                textColor: colors.onErrorContainer,
                onPressed: () =>
                    context.read<SalaryBloc>().add(const SalarySaveRequested()),
              ),
            ),
          );
      case SalarySaveStatus.idle || SalarySaveStatus.saving:
        break;
    }
  }
}

/// The content width from which the results and the inputs sit side by side.
const _twoColumnsFrom = 720.0;

/// The widest the content grows, so a form stays readable on a wide screen.
const _maxContentWidth = 1040.0;

class _SalaryContent extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final summary = [
                const SalarySectionSwitch(selected: SalarySection.month),
                const SizedBox(height: 16),
                const _MonthRow(),
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
                    constraints: const BoxConstraints(
                      maxWidth: _maxContentWidth,
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
                padding: const EdgeInsets.all(16),
                children: [...summary, const SizedBox(height: 24), ...inputs],
              );
            },
          ),
        ),
        const _SaveBar(),
      ],
    );
  }
}

class _MonthRow extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final month = context.select<SalaryBloc, YearMonth>(
      (bloc) => bloc.state.month,
    );

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: MonthChip(month: month, onPressed: () => _choose(context, month)),
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
);

/// The total after tax, and for a month paid in two payments the pay of each
/// part and the day it is paid.
class _Hero extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatter = context.moneyFormatter;
    final months = context.monthFormatter;

    final state = context.select<SalaryBloc, _HeroFigures>(
      (bloc) => (
        bloc.state.result,
        bloc.state.form.paymentMode,
        bloc.state.form.currency,
        bloc.state.month,
        bloc.state.form.firstPayDay,
        bloc.state.form.secondPayDay,
      ),
    );
    final (result, mode, currency, month, firstPayDay, secondPayDay) = state;
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
      (bloc) => bloc.state.result,
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

/// The pinned "Save month" button, just above the navigation bar.
class _SaveBar extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final canSave = context.select<SalaryBloc, bool>(
      (bloc) => bloc.state.canSave,
    );
    final isSaving = context.select<SalaryBloc, bool>(
      (bloc) => bloc.state.saveStatus == SalarySaveStatus.saving,
    );

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
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
                    : Text(context.l10n.saveMonthAction),
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
