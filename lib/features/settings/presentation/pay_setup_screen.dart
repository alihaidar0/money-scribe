import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/widgets/button_spinner.dart';
import 'package:money_scribe/core/widgets/day_stepper.dart';
import 'package:money_scribe/core/widgets/flow_page.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/settings/bloc/pay_schedule_bloc.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule_repository.dart';

/// AUTH-6 and AUTH-6b: the first-start question, how the salary is paid.
class PaySetupScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PayScheduleBloc(repository: context.read<PayScheduleRepository>()),
      child: const _PaySetupView(),
    );
  }
}

class _PaySetupView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocConsumer<PayScheduleBloc, PayScheduleState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == PayScheduleStatus.saved,
      listener: (context, state) => context.go(AppRoutes.overview),
      builder: (context, state) {
        final schedule = state.schedule;
        final isBusy = state.status == PayScheduleStatus.saving;
        final bloc = context.read<PayScheduleBloc>();

        return FlowPage(
          showBackButton: false,
          centered: true,
          failure: switch (state.status) {
            PayScheduleStatus.noConnection => FailureKind.noConnection,
            PayScheduleStatus.failure => FailureKind.error,
            _ => null,
          },
          onRetry: () => bloc.add(const PayScheduleConfirmed()),
          content: [
            Semantics(
              header: true,
              child: Text(l10n.payTitle, style: theme.textTheme.headlineMedium),
            ),
            const SizedBox(height: 8),
            Text(l10n.payHint, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            _ModeCard(
              title: l10n.payOneTitle,
              caption: l10n.payOneCaption,
              selected: schedule.mode == PaymentMode.onePayment,
              onTap: () =>
                  bloc.add(const PaymentModeSelected(PaymentMode.onePayment)),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              title: l10n.payTwoTitle,
              caption: l10n.payTwoCaption,
              selected: schedule.mode == PaymentMode.twoPayments,
              onTap: () =>
                  bloc.add(const PaymentModeSelected(PaymentMode.twoPayments)),
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
            const SizedBox(height: 32),
            FilledButton(
              onPressed: isBusy
                  ? null
                  : () => bloc.add(const PayScheduleConfirmed()),
              child: isBusy ? const ButtonSpinner() : Text(l10n.continueAction),
            ),
          ],
        );
      },
    );
  }
}

/// An outlined, radio-style card: the chosen one has a primary outline and a
/// check, so the choice does not rest on colour alone.
class _ModeCard extends StatelessWidget {
  const new({
    required this.title,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        caption,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ExcludeSemantics(
                  child: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected ? colors.primary : colors.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
