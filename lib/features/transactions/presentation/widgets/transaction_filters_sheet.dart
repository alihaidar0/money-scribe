import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/core/widgets/category_icons.dart';
import 'package:money_scribe/core/widgets/date_field.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';
import 'package:money_scribe/features/transactions/domain/transaction_filter.dart';
import 'package:money_scribe/features/transactions/presentation/account_icons.dart';

/// What the Filters sheet answers with: the choices to apply and the part of
/// the month to show.
final class TransactionFiltersResult {
  const new({required this.filter, required this.scope});

  final TransactionFilter filter;
  final PeriodScope scope;
}

/// TX-3 and TX-3b: the bottom sheet that narrows the transactions by category,
/// account and day, and for two payments by part of the month. Reset clears
/// every choice; Apply keeps them. Closes with a [TransactionFiltersResult],
/// or with `null` when dismissed.
Future<TransactionFiltersResult?> showTransactionFiltersSheet(
  BuildContext context, {
  required TransactionFilter filter,
  required PeriodScope scope,
  required bool twoPayments,
  required List<TransactionCategory> categories,
  required List<Account> accounts,
  required DateTime today,
}) {
  return showModalBottomSheet<TransactionFiltersResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Over the navigation bar too, which stays dimmed and inactive.
    useRootNavigator: true,
    builder: (sheetContext) => _FiltersSheet(
      filter: filter,
      scope: scope,
      twoPayments: twoPayments,
      categories: categories,
      accounts: accounts,
      today: today,
    ),
  );
}

class _FiltersSheet extends StatefulWidget {
  const new({
    required this.filter,
    required this.scope,
    required this.twoPayments,
    required this.categories,
    required this.accounts,
    required this.today,
  });

  final TransactionFilter filter;
  final PeriodScope scope;
  final bool twoPayments;
  final List<TransactionCategory> categories;
  final List<Account> accounts;
  final DateTime today;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late final Set<String> _categoryIds = {...widget.filter.categoryIds};
  late final Set<String> _accountIds = {...widget.filter.accountIds};
  late DateTime? _from = widget.filter.from;
  late DateTime? _to = widget.filter.to;
  late PeriodScope _scope = widget.scope;

  void _toggle(Set<String> ids, String id, {required bool selected}) {
    setState(() {
      if (selected) {
        ids.add(id);
      } else {
        ids.remove(id);
      }
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      TransactionFiltersResult(
        filter: TransactionFilter(
          categoryIds: _categoryIds,
          accountIds: _accountIds,
          from: _from,
          to: _to,
        ),
        scope: _scope,
      ),
    );
  }

  void _reset() {
    Navigator.of(context).pop(
      const TransactionFiltersResult(
        filter: TransactionFilter(),
        scope: PeriodScope.month,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    Widget section(String title, Widget child) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.labelLarge),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.filtersTitle, style: theme.textTheme.titleLarge),
            ),
            if (widget.twoPayments)
              section(
                l10n.filterPeriod,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (scope, label) in [
                      (PeriodScope.month, l10n.partMonth),
                      (PeriodScope.firstPart, l10n.partFirst),
                      (PeriodScope.secondPart, l10n.partSecond),
                    ])
                      ChoiceChip(
                        label: Text(label),
                        selected: _scope == scope,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _scope = scope),
                      ),
                  ],
                ),
              ),
            section(
              l10n.categoryLabel,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in widget.categories)
                    FilterChip(
                      avatar: Icon(categoryIcon(category.icon), size: 18),
                      label: Text(category.name),
                      selected: _categoryIds.contains(category.id),
                      onSelected: (selected) => _toggle(
                        _categoryIds,
                        category.id,
                        selected: selected,
                      ),
                    ),
                ],
              ),
            ),
            section(
              l10n.accountLabel,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final account in widget.accounts)
                    FilterChip(
                      avatar: Icon(accountIcon(account.kind), size: 18),
                      label: Text(account.name),
                      selected: _accountIds.contains(account.id),
                      onSelected: (selected) =>
                          _toggle(_accountIds, account.id, selected: selected),
                    ),
                ],
              ),
            ),
            section(
              l10n.filterDateRange,
              LayoutBuilder(
                builder: (context, constraints) {
                  final from = DateField(
                    label: l10n.fromLabel,
                    value: _from,
                    today: widget.today,
                    lastDate: _to,
                    onChanged: (date) => setState(() => _from = date),
                    onCleared: () => setState(() => _from = null),
                  );
                  final to = DateField(
                    label: l10n.toLabel,
                    value: _to,
                    today: widget.today,
                    firstDate: _from,
                    onChanged: (date) => setState(() => _to = date),
                    onCleared: () => setState(() => _to = null),
                  );
                  // Side by side while there is room, otherwise one under the
                  // other, so a date is never cut off.
                  return constraints.maxWidth >= 360 &&
                          MediaQuery.textScalerOf(context).scale(1) <= 1.3
                      ? Row(
                          children: [
                            Expanded(child: from),
                            const SizedBox(width: 12),
                            Expanded(child: to),
                          ],
                        )
                      : Column(
                          children: [from, const SizedBox(height: 12), to],
                        );
                },
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(onPressed: _reset, child: Text(l10n.resetAction)),
                FilledButton(onPressed: _apply, child: Text(l10n.applyAction)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
