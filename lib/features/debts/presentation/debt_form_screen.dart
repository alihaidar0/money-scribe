import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/routing/leave_screen.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/amount_field.dart';
import 'package:money_scribe/core/widgets/app_text_field.dart';
import 'package:money_scribe/core/widgets/confirm_dialogs.dart';
import 'package:money_scribe/core/widgets/date_field.dart';
import 'package:money_scribe/core/widgets/failure_snack_bar.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/core/widgets/pinned_button_bar.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/debts/bloc/debt_form_bloc.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';
import 'package:money_scribe/features/debts/domain/debts_repository.dart';

/// DB-2 and DB-8: the form that adds a debt, or with [id] changes one. Leaving
/// with changes asks first; saving closes it.
class DebtFormScreen extends StatelessWidget {
  const new({this.id, super.key});

  final String? id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DebtFormBloc(
        repository: context.read<DebtsRepository>(),
        now: context.read<Clock>().now,
        id: id,
      )..add(const DebtFormStarted()),
      child: const _FormView(),
    );
  }
}

/// DB-2: the form for a new debt.
class AddDebtScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const DebtFormScreen();
}

/// DB-8: the form for the debt [id], to change it.
class EditDebtScreen extends StatelessWidget {
  const new({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) => DebtFormScreen(id: id);
}

class _FormView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<DebtFormBloc>();
    final isEditing = context.select<DebtFormBloc, bool>(
      (bloc) => bloc.state.isEditing,
    );
    final isEdited = context.select<DebtFormBloc, bool>(
      (bloc) => bloc.state.isEdited,
    );

    return BlocListener<DebtFormBloc, DebtFormState>(
      listenWhen: (previous, current) =>
          previous.saveStatus != current.saveStatus ||
          previous.status != current.status,
      listener: (context, state) {
        if (state.status == DebtFormStatus.notFound ||
            state.saveStatus == DebtFormSaveStatus.saved) {
          context.leave(fallback: AppRoutes.debts);
          return;
        }
        if (state.saveStatus == DebtFormSaveStatus.failed) {
          showFailureSnackBar(
            context,
            l10n.couldNotSave,
            onRetry: () => bloc.add(const DebtSaveRequested()),
          );
        }
      },
      child: PopScope<Object?>(
        canPop: !isEdited,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final discard = await confirmDiscard(context);
          if (discard && context.mounted) {
            context.leave(fallback: AppRoutes.debts);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(isEditing ? l10n.editDebtTitle : l10n.addDebtTitle),
          ),
          bottomNavigationBar: BlocBuilder<DebtFormBloc, DebtFormState>(
            buildWhen: (previous, current) =>
                previous.status != current.status ||
                previous.canSave != current.canSave ||
                previous.saveStatus != current.saveStatus ||
                previous.isEditing != current.isEditing,
            builder: (context, state) => state.status != DebtFormStatus.ready
                ? const SizedBox.shrink()
                : PinnedButtonBar(
                    label: state.isEditing
                        ? l10n.saveChangesAction
                        : l10n.saveAction,
                    isBusy: state.saveStatus == DebtFormSaveStatus.saving,
                    onPressed: state.canSave
                        ? () => bloc.add(const DebtSaveRequested())
                        : null,
                  ),
          ),
          body: BlocBuilder<DebtFormBloc, DebtFormState>(
            buildWhen: (previous, current) => previous.status != current.status,
            builder: (context, state) => switch (state.status) {
              DebtFormStatus.loading ||
              DebtFormStatus.notFound => const _Skeleton(),
              DebtFormStatus.noConnection => FailureView(
                kind: FailureKind.noConnection,
                onRetry: () => bloc.add(const DebtFormRetried()),
              ),
              DebtFormStatus.failure => FailureView(
                kind: FailureKind.error,
                onRetry: () => bloc.add(const DebtFormRetried()),
              ),
              DebtFormStatus.ready => const _Form(),
            },
          ),
        ),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const new();

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final TextEditingController _person = TextEditingController(
    text: context.read<DebtFormBloc>().state.values.person,
  );
  late final TextEditingController _amount = TextEditingController(
    text: context.read<DebtFormBloc>().state.values.amountText,
  );
  late final TextEditingController _note = TextEditingController(
    text: context.read<DebtFormBloc>().state.values.note,
  );

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bloc = context.read<DebtFormBloc>();
    final today = context.read<Clock>().now();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: BlocBuilder<DebtFormBloc, DebtFormState>(
        buildWhen: (previous, current) => previous.values != current.values,
        builder: (context, state) {
          final values = state.values;
          final amount = state.amount;
          final repaid = state.repaid;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PillSegmentedButton<DebtDirection>(
                segments: [
                  ButtonSegment(
                    value: DebtDirection.lent,
                    label: Text(l10n.iLent),
                  ),
                  ButtonSegment(
                    value: DebtDirection.borrowed,
                    label: Text(l10n.iBorrowed),
                  ),
                ],
                selected: {values.direction},
                onSelectionChanged: (selection) =>
                    bloc.add(DebtDirectionSelected(selection.first)),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _person,
                label: l10n.personLabel,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(DebtDraft.maxPersonLength),
                ],
                onChanged: (text) => bloc.add(DebtPersonChanged(text)),
              ),
              const SizedBox(height: 16),
              AmountField(
                controller: _amount,
                label: l10n.amountLabel,
                currency: state.currency,
                hintText: '0.00',
                alwaysFloatLabel: true,
                style: theme.textTheme.displaySmall,
                errorText: state.amountBelowRepaid && repaid != null
                    ? l10n.debtAmountBelowRepaid(
                        repaid: context.moneyFormatter.format(repaid),
                      )
                    : values.amountText.isNotEmpty &&
                          (amount == null || !amount.isPositive)
                    ? l10n.amountInvalid
                    : null,
                textInputAction: TextInputAction.next,
                onChanged: (text) => bloc.add(DebtAmountChanged(text)),
              ),
              const SizedBox(height: 16),
              DateField(
                label: l10n.startDateLabel,
                value: values.startDate,
                today: today,
                onChanged: (date) => bloc.add(DebtStartDateChosen(date)),
              ),
              const SizedBox(height: 16),
              DateField(
                label: l10n.dueDateOptionalLabel,
                value: values.dueDate,
                today: today,
                onChanged: (date) => bloc.add(DebtDueDateChosen(date)),
                onCleared: () => bloc.add(const DebtDueDateCleared()),
              ),
              if (state.dueBeforeStart)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16, top: 4),
                  child: Text(
                    l10n.dueBeforeStartError,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _note,
                label: l10n.noteLabel,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(DebtDraft.maxNoteLength),
                ],
                onChanged: (text) => bloc.add(DebtNoteChanged(text)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          SkeletonBox(height: 48, radius: 24),
          SizedBox(height: 16),
          SkeletonBox(height: 56),
          SizedBox(height: 16),
          SkeletonBox(height: 88),
          SizedBox(height: 16),
          SkeletonBox(height: 56),
          SizedBox(height: 16),
          SkeletonBox(height: 56),
        ],
      ),
    );
  }
}
