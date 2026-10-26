import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/routing/leave_screen.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/amount_field.dart';
import 'package:money_scribe/core/widgets/app_text_field.dart';
import 'package:money_scribe/core/widgets/category_icons.dart';
import 'package:money_scribe/core/widgets/confirm_dialogs.dart';
import 'package:money_scribe/core/widgets/date_field.dart';
import 'package:money_scribe/core/widgets/failure_snack_bar.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/core/widgets/pinned_button_bar.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/transactions/bloc/transaction_form_bloc.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';
import 'package:money_scribe/features/transactions/domain/accounts_repository.dart';
import 'package:money_scribe/features/transactions/domain/categories_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';
import 'package:money_scribe/features/transactions/domain/transactions_repository.dart';
import 'package:money_scribe/features/transactions/presentation/account_icons.dart';
import 'package:money_scribe/features/transactions/presentation/category_names.dart';
import 'package:money_scribe/features/transactions/presentation/widgets/account_sheet.dart';

/// TX-4, TX-5, TX-6 and TX-7: the form that adds a transaction, or with [id]
/// changes or deletes one. The amount comes first. Leaving with changes asks
/// first; saving or deleting closes it.
class TransactionFormScreen extends StatelessWidget {
  const new({this.id, super.key});

  final String? id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TransactionFormBloc(
        transactions: context.read<TransactionsRepository>(),
        accounts: context.read<AccountsRepository>(),
        categories: context.read<CategoriesRepository>(),
        now: context.read<Clock>().now,
        id: id,
      )..add(const TransactionFormStarted()),
      child: const _FormView(),
    );
  }
}

class _FormView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<TransactionFormBloc>();
    final isEditing = context.select<TransactionFormBloc, bool>(
      (bloc) => bloc.state.isEditing,
    );
    final isEdited = context.select<TransactionFormBloc, bool>(
      (bloc) => bloc.state.isEdited,
    );
    final canDelete = context.select<TransactionFormBloc, bool>(
      (bloc) =>
          bloc.state.status == TransactionFormStatus.ready &&
          bloc.state.deleteStatus != TransactionFormDeleteStatus.deleting,
    );

    return BlocListener<TransactionFormBloc, TransactionFormState>(
      listenWhen: (previous, current) =>
          previous.saveStatus != current.saveStatus ||
          previous.deleteStatus != current.deleteStatus ||
          previous.status != current.status,
      listener: (context, state) {
        if (state.status == TransactionFormStatus.notFound ||
            state.saveStatus == TransactionFormSaveStatus.saved ||
            state.deleteStatus == TransactionFormDeleteStatus.deleted) {
          context.leave(fallback: AppRoutes.transactions);
          return;
        }
        if (state.saveStatus == TransactionFormSaveStatus.failed) {
          showFailureSnackBar(
            context,
            l10n.couldNotSave,
            onRetry: () => bloc.add(const TransactionSaveRequested()),
          );
        }
        if (state.deleteStatus == TransactionFormDeleteStatus.failed) {
          showFailureSnackBar(
            context,
            l10n.couldNotDelete,
            onRetry: () => bloc.add(const TransactionDeleteRequested()),
          );
        }
      },
      child: PopScope<Object?>(
        canPop: !isEdited,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final discard = await confirmDiscard(context);
          if (discard && context.mounted) {
            context.leave(fallback: AppRoutes.transactions);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              isEditing ? l10n.editTransactionTitle : l10n.addTransactionTitle,
            ),
            actions: [
              if (isEditing && canDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.deleteTransactionTooltip,
                  onPressed: () => _delete(context),
                ),
            ],
          ),
          bottomNavigationBar:
              BlocBuilder<TransactionFormBloc, TransactionFormState>(
                buildWhen: (previous, current) =>
                    previous.status != current.status ||
                    previous.canSave != current.canSave ||
                    previous.saveStatus != current.saveStatus ||
                    previous.isEditing != current.isEditing,
                builder: (context, state) =>
                    state.status != TransactionFormStatus.ready
                    ? const SizedBox.shrink()
                    : PinnedButtonBar(
                        label: state.isEditing
                            ? l10n.saveChangesAction
                            : l10n.saveAction,
                        isBusy:
                            state.saveStatus ==
                            TransactionFormSaveStatus.saving,
                        onPressed: state.canSave
                            ? () => bloc.add(const TransactionSaveRequested())
                            : null,
                      ),
              ),
          body: BlocBuilder<TransactionFormBloc, TransactionFormState>(
            buildWhen: (previous, current) => previous.status != current.status,
            builder: (context, state) => switch (state.status) {
              TransactionFormStatus.loading ||
              TransactionFormStatus.notFound => const _Skeleton(),
              TransactionFormStatus.noConnection => FailureView(
                kind: FailureKind.noConnection,
                onRetry: () => bloc.add(const TransactionFormRetried()),
              ),
              TransactionFormStatus.failure => FailureView(
                kind: FailureKind.error,
                onRetry: () => bloc.add(const TransactionFormRetried()),
              ),
              TransactionFormStatus.ready => const _Form(),
            },
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final bloc = context.read<TransactionFormBloc>();
    final l10n = context.l10n;
    final confirmed = await confirmDelete(
      context,
      title: l10n.deleteTransactionTitle,
      message: l10n.deleteTransactionMessage,
    );
    if (confirmed) bloc.add(const TransactionDeleteRequested());
  }
}

class _Form extends StatefulWidget {
  const new();

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final TextEditingController _amount = TextEditingController(
    text: context.read<TransactionFormBloc>().state.values.amountText,
  );
  late final TextEditingController _note = TextEditingController(
    text: context.read<TransactionFormBloc>().state.values.note,
  );

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _chooseAccount(BuildContext context) async {
    final bloc = context.read<TransactionFormBloc>();
    final state = bloc.state;
    final result = await showAccountSheet(
      context,
      accounts: state.accounts,
      selectedId: state.values.accountId,
    );
    switch (result) {
      case AccountChosen(:final account):
        bloc.add(TransactionAccountChosen(account.id));
      case AddAccountRequested() || ManageAccountsRequested():
        if (!context.mounted) break;
        await context.push<void>(AppRoutes.accounts);
        bloc.add(const TransactionAccountsRefreshed());
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bloc = context.read<TransactionFormBloc>();
    final today = context.read<Clock>().now();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: BlocBuilder<TransactionFormBloc, TransactionFormState>(
        buildWhen: (previous, current) =>
            previous.values != current.values ||
            previous.categories != current.categories ||
            previous.accounts != current.accounts,
        builder: (context, state) {
          final values = state.values;
          final amountText = values.amountText;
          final amount = Money.tryParse(amountText, state.currency);
          final amountInvalid =
              amountText.isNotEmpty && (amount == null || !amount.isPositive);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PillSegmentedButton<TransactionKind>(
                segments: [
                  ButtonSegment(
                    value: TransactionKind.expense,
                    label: Text(l10n.transactionExpense),
                  ),
                  ButtonSegment(
                    value: TransactionKind.income,
                    label: Text(l10n.transactionIncome),
                  ),
                ],
                selected: {values.kind},
                onSelectionChanged: (selection) =>
                    bloc.add(TransactionKindSelected(selection.first)),
              ),
              const SizedBox(height: 16),
              AmountField(
                controller: _amount,
                label: l10n.amountLabel,
                currency: state.currency,
                hintText: '0.00',
                alwaysFloatLabel: true,
                style: theme.textTheme.displaySmall,
                errorText: amountInvalid ? l10n.amountInvalid : null,
                textInputAction: TextInputAction.next,
                onChanged: (text) => bloc.add(TransactionAmountChanged(text)),
              ),
              const SizedBox(height: 16),
              DateField(
                label: l10n.dateLabel,
                value: values.date,
                today: today,
                onChanged: (date) => bloc.add(TransactionDateChosen(date)),
              ),
              if (state.twoPayments)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16, top: 4),
                  child: Text(
                    PeriodScope.partOfDay(values.date.day) ==
                            PeriodScope.firstPart
                        ? l10n.datePartFirst
                        : l10n.datePartSecond,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  l10n.categoryLabel,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in state.availableCategories)
                    ChoiceChip(
                      avatar: Icon(categoryIcon(category.icon), size: 18),
                      label: Text(context.l10n.categoryName(category)),
                      selected: values.categoryId == category.id,
                      showCheckmark: false,
                      onSelected: (_) =>
                          bloc.add(TransactionCategoryChosen(category.id)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _AccountRow(
                name: state.account?.name ?? '',
                icon: accountIcon(state.account?.kind ?? AccountKind.card),
                onTap: () => _chooseAccount(context),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _note,
                label: l10n.noteLabel,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                    TransactionDraft.maxNoteLength,
                  ),
                ],
                onChanged: (text) => bloc.add(TransactionNoteChanged(text)),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The row "Card ⌄" that opens the account sheet.
class _AccountRow extends StatelessWidget {
  const new({required this.name, required this.icon, required this.onTap});

  final String name;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: l10n.accountLabel,
      value: name,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.accountLabel,
            prefixIcon: Icon(icon),
            suffixIcon: const Icon(Icons.expand_more),
          ),
          child: Text(name, style: theme.textTheme.bodyLarge),
        ),
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
          SkeletonBox(height: 88),
          SizedBox(height: 16),
          SkeletonBox(height: 56),
          SizedBox(height: 16),
          SkeletonBox(height: 56),
          SizedBox(height: 16),
          SkeletonBox(height: 56),
        ],
      ),
    );
  }
}
