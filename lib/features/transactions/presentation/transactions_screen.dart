import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/categories/category_icon.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/text/api_text_formatter.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';
import 'package:money_scribe/core/theme/money_colors.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/category_icons.dart';
import 'package:money_scribe/core/widgets/confirm_dialogs.dart';
import 'package:money_scribe/core/widgets/failure_snack_bar.dart';
import 'package:money_scribe/core/widgets/icon_circle.dart';
import 'package:money_scribe/core/widgets/part_selector.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/core/widgets/top_level_screen.dart';
import 'package:money_scribe/features/transactions/bloc/transactions_bloc.dart';
import 'package:money_scribe/features/transactions/domain/accounts_repository.dart';
import 'package:money_scribe/features/transactions/domain/categories_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';
import 'package:money_scribe/features/transactions/domain/transaction_filter.dart';
import 'package:money_scribe/features/transactions/domain/transaction_groups.dart';
import 'package:money_scribe/features/transactions/domain/transactions_repository.dart';
import 'package:money_scribe/features/transactions/presentation/widgets/transaction_filters_sheet.dart';

/// TX-1, TX-2, TX-8 to TX-12: every transaction, newest first, grouped by day
/// (and for two payments by part of the month), with a search, filters and
/// the button that adds one. Tapping a row opens it to be changed.
///
/// Another screen can send the person here with one category of one [month]
/// (and, for two payments, one [part] of it) already chosen, such as a row of
/// the Reports. A different [requestId] asks for it again even when the
/// request is the same.
class TransactionsScreen extends StatefulWidget {
  const new({
    this.categoryId,
    this.month,
    this.part,
    this.requestId,
    super.key,
  });

  final String? categoryId;
  final YearMonth? month;
  final PeriodScope? part;
  final int? requestId;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final TransactionsBloc _bloc = TransactionsBloc(
    transactions: context.read<TransactionsRepository>(),
    accounts: context.read<AccountsRepository>(),
    categories: context.read<CategoriesRepository>(),
  )..add(const TransactionsStarted());

  @override
  void initState() {
    super.initState();
    _applyRequest();
  }

  @override
  void didUpdateWidget(TransactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categoryId != oldWidget.categoryId ||
        widget.month != oldWidget.month ||
        widget.part != oldWidget.part ||
        widget.requestId != oldWidget.requestId) {
      _applyRequest();
    }
  }

  /// Narrows the list to the category and month of the request, if any.
  void _applyRequest() {
    final categoryId = widget.categoryId;
    if (categoryId == null) return;
    final month = widget.month;
    _bloc.add(
      TransactionFiltersApplied(
        TransactionFilter(
          categoryIds: {categoryId},
          from: month?.firstDay,
          to: month == null ? null : DateTime(month.year, month.month + 1, 0),
        ),
        widget.part ?? PeriodScope.month,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_bloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(value: _bloc, child: const _TransactionsView());
  }
}

/// Opens the form that adds a transaction, and shows what it did when it
/// closes.
Future<void> _addTransaction(BuildContext context) async {
  final bloc = context.read<TransactionsBloc>();
  await context.push<void>(AppRoutes.addTransaction);
  bloc.add(const TransactionsRefreshed());
}

/// Opens the transaction [id] to be changed, and shows what it did when it
/// closes.
Future<void> _openTransaction(BuildContext context, String id) async {
  final bloc = context.read<TransactionsBloc>();
  await context.push<void>(AppRoutes.editTransactionPath(id));
  bloc.add(const TransactionsRefreshed());
}

class _TransactionsView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<TransactionsBloc>();
    final showAdd = context.select<TransactionsBloc, bool>(
      (bloc) =>
          bloc.state.status == TransactionsStatus.ready &&
          bloc.state.hasTransactions,
    );

    return BlocListener<TransactionsBloc, TransactionsState>(
      listenWhen: (previous, current) =>
          previous.deleteStatus != current.deleteStatus &&
          current.deleteStatus == TransactionsDeleteStatus.failed,
      listener: (context, state) {
        final id = state.deletingId;
        if (id == null) return;
        showFailureSnackBar(
          context,
          l10n.couldNotDelete,
          onRetry: () => bloc.add(TransactionDeleteConfirmed(id)),
        );
      },
      child: _screen(context, showAdd),
    );
  }

  Widget _screen(BuildContext context, bool showAdd) {
    final l10n = context.l10n;
    final bloc = context.read<TransactionsBloc>();

    return TopLevelScreen(
      title: l10n.transactionsTitle,
      floatingActionButton: showAdd
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => _addTransaction(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addAction),
            )
          : null,
      body: BlocBuilder<TransactionsBloc, TransactionsState>(
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.hasTransactions != current.hasTransactions,
        builder: (context, state) => switch (state.status) {
          TransactionsStatus.loading => const _Skeleton(),
          TransactionsStatus.noConnection => FailureView(
            kind: FailureKind.noConnection,
            onRetry: () => bloc.add(const TransactionsRetried()),
          ),
          TransactionsStatus.failure => FailureView(
            kind: FailureKind.error,
            errorTitle: l10n.transactionsLoadFailed,
            onRetry: () => bloc.add(const TransactionsRetried()),
          ),
          TransactionsStatus.ready when !state.hasTransactions => StateView(
            icon: Icons.receipt_long_outlined,
            title: l10n.transactionsEmptyTitle,
            actionLabel: l10n.addFirstPurchaseAction,
            filledAction: true,
            onAction: () => _addTransaction(context),
          ),
          TransactionsStatus.ready => const _Content(),
        },
      ),
    );
  }
}

/// The widest the list grows, so a row stays readable on a wide screen.
const _maxContentWidth = 720.0;

/// The content width from which the list and the detail of the chosen
/// transaction sit side by side (the expanded window size class).
const _detailPaneFrom = 840.0;

class _Content extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _detailPaneFrom) {
          return const Row(
            children: [
              Expanded(flex: 5, child: _ListPane(wide: true)),
              VerticalDivider(width: 1),
              Expanded(flex: 4, child: _DetailPane()),
            ],
          );
        }
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: const _ListPane(wide: false),
          ),
        );
      },
    );
  }
}

/// The part selector, the search, the filters and the list. With [wide], a row
/// shows its transaction in the detail pane instead of opening it.
class _ListPane extends StatelessWidget {
  const new({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final twoPayments = context.select<TransactionsBloc, bool>(
      (bloc) => bloc.state.twoPayments,
    );

    return Column(
      children: [
        if (twoPayments)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: BlocBuilder<TransactionsBloc, TransactionsState>(
              buildWhen: (previous, current) => previous.scope != current.scope,
              builder: (context, state) => PartSelector(
                selected: state.scope,
                onSelected: (scope) => context.read<TransactionsBloc>().add(
                  TransactionsScopeSelected(scope),
                ),
              ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _SearchField(),
        ),
        const _FilterBar(),
        Expanded(child: _Results(wide: wide)),
      ],
    );
  }
}

/// TB-1, right pane: everything about the chosen transaction, with the buttons
/// that edit and delete it.
class _DetailPane extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = context.watch<TransactionsBloc>().state;
    final transaction = state.selected;
    if (transaction == null) return const SizedBox.shrink();

    final colors = context.moneyColors;
    final today = context.read<Clock>().now();
    final category = state.categories
        .where((item) => item.id == transaction.categoryId)
        .firstOrNull;
    final account = state.accounts
        .where((item) => item.id == transaction.accountId)
        .firstOrNull;
    final money = transaction.kind == TransactionKind.income
        ? colors.income
        : colors.expense;
    final deleting = state.deleteStatus == TransactionsDeleteStatus.deleting;

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      context.moneyFormatter.formatSigned(
                        transaction.signedAmount,
                      ),
                      style: theme.textTheme.displaySmall?.amount.copyWith(
                        color: money.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _DetailLine(
                    label: l10n.categoryLabel,
                    value: category?.name ?? '',
                    icon: categoryIcon(category?.icon ?? CategoryIcon.other),
                  ),
                  _DetailLine(
                    label: l10n.dateLabel,
                    value: context.dayFormatter.formatWithWeekday(
                      transaction.date,
                      today: today,
                    ),
                  ),
                  _DetailLine(
                    label: l10n.accountLabel,
                    value: account?.name ?? '',
                  ),
                  if (transaction.note.isNotEmpty)
                    _DetailLine(label: l10n.noteLabel, value: transaction.note),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            _openTransaction(context, transaction.id),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l10n.editAction),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        onPressed: deleting
                            ? null
                            : () => _delete(context, transaction.id),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.deleteAction),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, String id) async {
    final bloc = context.read<TransactionsBloc>();
    final l10n = context.l10n;
    final confirmed = await confirmDelete(
      context,
      title: l10n.deleteTransactionTitle,
      message: l10n.deleteTransactionMessage,
    );
    if (confirmed) bloc.add(TransactionDeleteConfirmed(id));
  }
}

/// A label with its value, one under the other.
class _DetailLine extends StatelessWidget {
  const new({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            IconCircle(icon: icon!, size: 40),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The search field. Its text follows the Bloc, so clearing the filters also
/// clears it.
class _SearchField extends StatefulWidget {
  const new();

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: context.read<TransactionsBloc>().state.filter.query,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocListener<TransactionsBloc, TransactionsState>(
      listenWhen: (previous, current) =>
          previous.filter.query != current.filter.query,
      listener: (context, state) {
        if (_controller.text != state.filter.query) {
          _controller.text = state.filter.query;
        }
      },
      child: TextField(
        controller: _controller,
        inputFormatters: const [ApiTextFormatter()],
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.transactionSearchHint,
          prefixIcon: const Icon(Icons.search),
        ),
        onChanged: (text) =>
            context.read<TransactionsBloc>().add(TransactionsSearched(text)),
      ),
    );
  }
}

/// The Filters button, which opens the Filters sheet, with a count of the
/// choices that are on, and a chip for each of them to take it off again.
class _FilterBar extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<TransactionsBloc>().state;
    final count =
        state.filter.sheetFilterCount +
        (state.effectiveScope == PeriodScope.month ? 0 : 1);
    final label = count == 0
        ? l10n.filtersTitle
        : l10n.filterChipCount(label: l10n.filtersTitle, count: count);
    final chips = _activeChips(context, state);

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (count == 0)
              OutlinedButton.icon(
                onPressed: () => _openFilters(context),
                icon: const Icon(Icons.tune),
                label: Text(label),
              )
            else
              FilledButton.tonalIcon(
                onPressed: () => _openFilters(context),
                icon: const Icon(Icons.tune),
                label: Text(label),
              ),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: chips),
            ],
          ],
        ),
      ),
    );
  }

  /// A chip for each category, each account, the days and the part of the
  /// month that narrow the list. Its cross takes that choice off.
  List<Widget> _activeChips(BuildContext context, TransactionsState state) {
    final l10n = context.l10n;
    final days = context.dayFormatter;
    final today = context.read<Clock>().now();
    final bloc = context.read<TransactionsBloc>();
    final filter = state.filter;
    final scope = state.effectiveScope;

    Widget chip(String label, VoidCallback onRemove) {
      return InputChip(
        label: Text(label),
        deleteButtonTooltipMessage: l10n.removeFilterTooltip(name: label),
        onDeleted: onRemove,
      );
    }

    void apply(TransactionFilter filter, PeriodScope scope) {
      bloc.add(TransactionFiltersApplied(filter, scope));
    }

    final from = filter.from;
    final to = filter.to;

    return [
      if (scope != PeriodScope.month)
        chip(
          scope == PeriodScope.firstPart ? l10n.partFirst : l10n.partSecond,
          () => apply(filter, PeriodScope.month),
        ),
      for (final id in filter.categoryIds)
        chip(
          state.categories
                  .where((category) => category.id == id)
                  .firstOrNull
                  ?.name ??
              id,
          () => apply(filter.withoutCategory(id), scope),
        ),
      for (final id in filter.accountIds)
        chip(
          state.accounts
                  .where((account) => account.id == id)
                  .firstOrNull
                  ?.name ??
              id,
          () => apply(filter.withoutAccount(id), scope),
        ),
      if (from != null || to != null)
        chip(
          from != null && to != null
              ? l10n.filterDatesChip(
                  from: days.formatDate(from, today: today),
                  to: days.formatDate(to, today: today),
                )
              : from != null
              ? l10n.filterFromChip(date: days.formatDate(from, today: today))
              : l10n.filterToChip(date: days.formatDate(to!, today: today)),
          () => apply(filter.withoutDates(), scope),
        ),
    ];
  }

  Future<void> _openFilters(BuildContext context) async {
    final bloc = context.read<TransactionsBloc>();
    final state = bloc.state;
    final result = await showTransactionFiltersSheet(
      context,
      filter: state.filter,
      scope: state.effectiveScope,
      twoPayments: state.twoPayments,
      categories: state.categories,
      accounts: state.accounts,
      today: context.read<Clock>().now(),
    );
    if (result != null) {
      bloc.add(TransactionFiltersApplied(result.filter, result.scope));
    }
  }
}

/// The transactions that pass the search and filters, or TX-8 when none do.
class _Results extends StatelessWidget {
  const new({required this.wide});

  /// Whether the detail pane is beside the list.
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<TransactionsBloc>().state;
    final visible = state.visible;

    if (visible.isEmpty) {
      return StateView(
        icon: Icons.search_off,
        title: l10n.noResultsTitle,
        message: l10n.noResultsMessage,
        actionLabel: l10n.clearFiltersAction,
        onAction: () => context.read<TransactionsBloc>().add(
          const TransactionFiltersCleared(),
        ),
      );
    }

    final entries = <_Entry>[];
    if (state.twoPayments) {
      for (final period in TransactionGroups.byPeriod(visible)) {
        entries.add(_PeriodEntry(period));
        for (final day in period.days) {
          entries
            ..add(_DayEntry(day))
            ..addAll(day.transactions.map(_TransactionEntry.new));
        }
      }
    } else {
      for (final day in TransactionGroups.byDay(visible)) {
        entries
          ..add(_DayEntry(day))
          ..addAll(day.transactions.map(_TransactionEntry.new));
      }
    }

    final categories = {
      for (final category in state.categories) category.id: category,
    };
    final accounts = {
      for (final account in state.accounts) account.id: account,
    };

    return ListView.builder(
      // Room under the last row for the button.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: entries.length,
      itemBuilder: (context, index) => switch (entries[index]) {
        _PeriodEntry(:final period) => _PeriodHeader(period: period),
        _DayEntry(:final day) => _DayHeader(day: day),
        _TransactionEntry(:final transaction) => _TransactionRow(
          transaction: transaction,
          categoryName: categories[transaction.categoryId]?.name ?? '',
          icon: categoryIcon(
            categories[transaction.categoryId]?.icon ?? CategoryIcon.other,
          ),
          accountName: accounts[transaction.accountId]?.name ?? '',
          selected: wide && transaction.id == state.selected?.id,
          onTap: wide
              ? () => context.read<TransactionsBloc>().add(
                  TransactionSelected(transaction.id),
                )
              : () => _openTransaction(context, transaction.id),
        ),
      },
    );
  }
}

sealed class _Entry {
  const new();
}

final class _PeriodEntry extends _Entry {
  const new(this.period);

  final PeriodGroup period;
}

final class _DayEntry extends _Entry {
  const new(this.day);

  final DayGroup day;
}

final class _TransactionEntry extends _Entry {
  const new(this.transaction);

  final Transaction transaction;
}

/// "Part 2 · 16th–31st Oct": a tonal bar that starts a part of a month.
class _PeriodHeader extends StatelessWidget {
  const new({required this.period});

  final PeriodGroup period;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final days = context.dayFormatter;
    final months = context.monthFormatter;
    final today = context.read<Clock>().now();

    final first = period.part == PeriodScope.firstPart;
    final lastDay = first
        ? PeriodScope.lastDayOfFirstPart
        : TransactionGroups.lastDayOf(period.month);
    final monthName = period.month.year == today.year
        ? months.shortName(period.month.month)
        : months.format(period.month);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Semantics(
        header: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              l10n.partRangeLabel(
                part: first ? l10n.partFirst : l10n.partSecond,
                from: days.ordinal(
                  first ? 1 : PeriodScope.lastDayOfFirstPart + 1,
                ),
                to: days.ordinal(lastDay),
                month: monthName,
              ),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A day with what its transactions come to at the end.
class _DayHeader extends StatelessWidget {
  const new({required this.day});

  final DayGroup day;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    final today = context.read<Clock>().now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final String name;
    if (day.date == todayDate) {
      name = l10n.todayLabel;
    } else if (day.date == DateTime(today.year, today.month, today.day - 1)) {
      name = l10n.yesterdayLabel;
    } else {
      name = context.dayFormatter.formatWithWeekday(day.date, today: today);
    }
    final total = day.total;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Semantics(
        header: true,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, end: 4),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            children: [
              Text(name, style: theme.textTheme.titleSmall),
              Text(
                context.moneyFormatter.formatSigned(total),
                style: theme.textTheme.titleSmall?.amount.copyWith(
                  color: total.isNegative
                      ? colors.expense.color
                      : colors.income.color,
                ),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tonal row: the category icon, its name with the note and the account, and
/// the signed amount. Income is green with a plus, an expense red with a minus.
class _TransactionRow extends StatelessWidget {
  const new({
    required this.transaction,
    required this.categoryName,
    required this.icon,
    required this.accountName,
    required this.selected,
    required this.onTap,
  });

  final Transaction transaction;
  final String categoryName;
  final IconData icon;
  final String accountName;

  /// Whether the detail pane shows this transaction.
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    final income = transaction.kind == TransactionKind.income;
    final money = income ? colors.income : colors.expense;
    final details = [
      if (transaction.note.isNotEmpty) transaction.note,
      accountName,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
                child: Row(
                  children: [
                    IconCircle(icon: icon, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                categoryName,
                                style: theme.textTheme.bodyLarge,
                              ),
                              Text(
                                details,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            context.moneyFormatter.formatSigned(
                              transaction.signedAmount,
                            ),
                            style: theme.textTheme.titleMedium?.amount.copyWith(
                              color: money.color,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const SkeletonBox(height: 56, radius: 28),
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
