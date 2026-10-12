import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/routing/navigation_extensions.dart';
import 'package:money_scribe/core/widgets/day_stepper.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/core/widgets/pinned_button_bar.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/settings/bloc/pay_schedule_bloc.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule_repository.dart';

/// ST-3: how the salary is paid: one payment a month or two, the pay days, and
/// the reminder. It sets how new months are created; a saved month is
/// corrected on its own Salary screen. Saving goes back to the Settings.
class PayScheduleScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PayScheduleBloc(
        repository: context.read<PayScheduleRepository>(),
        // Loading from the first frame: the default schedule is never
        // shown in place of the saved one.
        initialState: const PayScheduleState(
          status: PayScheduleStatus.loading,
          isLoaded: false,
        ),
      )..add(const PayScheduleStarted()),
      child: const _PayScheduleView(),
    );
  }
}

class _PayScheduleView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<PayScheduleBloc, PayScheduleState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == PayScheduleStatus.saved,
      listener: (context, state) => context.popOrGo(AppRoutes.settings),
      builder: (context, state) {
        final bloc = context.read<PayScheduleBloc>();
        final failure = switch (state.status) {
          PayScheduleStatus.noConnection => FailureKind.noConnection,
          PayScheduleStatus.failure => FailureKind.error,
          _ => null,
        };
        final isLoading = state.status == PayScheduleStatus.loading;
        final isBusy = state.status == PayScheduleStatus.saving;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.payScheduleTitle)),
          body: isLoading
              ? const _Skeleton()
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    // The form keeps what was chosen while a failure to save
                    // is shown.
                    if (state.isLoaded)
                      Offstage(
                        offstage: failure != null,
                        child: _Form(state: state, isBusy: isBusy),
                      ),
                    if (failure != null)
                      Positioned.fill(
                        child: FailureView(
                          kind: failure,
                          onRetry: () => bloc.add(
                            state.isLoaded
                                ? const PayScheduleConfirmed()
                                : const PayScheduleStarted(),
                          ),
                        ),
                      ),
                  ],
                ),
          bottomNavigationBar: state.isLoaded && !isLoading && failure == null
              ? PinnedButtonBar(
                  label: l10n.saveAction,
                  isBusy: isBusy,
                  onPressed: isBusy
                      ? null
                      : () => bloc.add(const PayScheduleConfirmed()),
                )
              : null,
        );
      },
    );
  }
}

class _Form extends StatelessWidget {
  const new({required this.state, required this.isBusy});

  final PayScheduleState state;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bloc = context.read<PayScheduleBloc>();
    final schedule = state.schedule;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.paymentsPerMonthLabel,
            style: theme.textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 8),
        PillSegmentedButton<PaymentMode>(
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
          selected: {schedule.mode},
          onSelectionChanged: isBusy
              ? null
              : (selection) => bloc.add(PaymentModeSelected(selection.first)),
        ),
        if (schedule.mode == PaymentMode.twoPayments) ...[
          const SizedBox(height: 24),
          DayStepper(
            label: l10n.firstPayDay,
            value: schedule.firstPayDay,
            min: PaySchedule.firstDayOfMonth,
            max: PaySchedule.lastDayOfMonth,
            onChanged: (day) => bloc.add(FirstPayDayChanged(day)),
          ),
          const SizedBox(height: 12),
          DayStepper(
            label: l10n.secondPayDay,
            caption: l10n.ofNextMonth,
            value: schedule.secondPayDay,
            min: PaySchedule.firstDayOfMonth,
            max: PaySchedule.lastDayOfMonth,
            onChanged: (day) => bloc.add(SecondPayDayChanged(day)),
          ),
        ],
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.remindOnPayDays),
          value: schedule.remindOnPayDays,
          onChanged: isBusy
              ? null
              : (remind) => bloc.add(RemindOnPayDaysChanged(remind: remind)),
        ),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.payScheduleNote,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const SkeletonScope(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SkeletonBox(height: 40, radius: 20),
            SizedBox(height: 24),
            SkeletonBox(height: 56),
            SizedBox(height: 12),
            SkeletonBox(height: 56),
          ],
        ),
      ),
    );
  }
}
