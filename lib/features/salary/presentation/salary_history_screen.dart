import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/core/widgets/success_snack_bar.dart';
import 'package:money_scribe/features/salary/bloc/salary_history_bloc.dart';
import 'package:money_scribe/features/salary/domain/salary_history_entry.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';
import 'package:money_scribe/features/salary/presentation/salary_edit_screen.dart';

/// SAL-6, SAL-7 and SAL-15: the saved months, newest first. A month paid in
/// one payment is one card; a month paid in two has a header and a row for
/// each part. Tapping one opens the month to be corrected.
class SalaryHistoryScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SalaryHistoryBloc(
        repository: context.read<SalaryRepository>(),
        now: context.read<Clock>().now,
      )..add(const SalaryHistoryStarted()),
      child: const _SalaryHistoryView(),
    );
  }
}

/// Makes every "new month" request different, so the Salary screen opens the
/// month again even when it is the same one.
int _requests = 0;

void _startNewMonth(BuildContext context) {
  final month = context.read<SalaryHistoryBloc>().state.newMonth;
  context.go(AppRoutes.salaryTab(month), extra: ++_requests);
}

class _SalaryHistoryView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<SalaryHistoryBloc>();
    final hasMonths = context.select<SalaryHistoryBloc, bool>(
      (bloc) =>
          bloc.state.status == SalaryHistoryStatus.ready && !bloc.state.isEmpty,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.salaryHistoryTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: l10n.compareMonthsTitle,
            onPressed: () => context.push(AppRoutes.salaryCompare),
          ),
        ],
      ),
      body: BlocBuilder<SalaryHistoryBloc, SalaryHistoryState>(
        builder: (context, state) => switch (state.status) {
          SalaryHistoryStatus.loading => const _HistorySkeleton(),
          SalaryHistoryStatus.noConnection => FailureView(
            kind: FailureKind.noConnection,
            onRetry: () => bloc.add(const SalaryHistoryRetried()),
          ),
          SalaryHistoryStatus.failure => FailureView(
            kind: FailureKind.error,
            onRetry: () => bloc.add(const SalaryHistoryRetried()),
          ),
          SalaryHistoryStatus.ready when state.isEmpty => StateView(
            icon: Icons.history,
            title: l10n.salaryHistoryEmptyTitle,
            actionLabel: l10n.enterMonthAction,
            filledAction: true,
            onAction: () => _startNewMonth(context),
          ),
          SalaryHistoryStatus.ready => _HistoryList(entries: state.entries),
        },
      ),
      floatingActionButton: hasMonths
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => _startNewMonth(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.newMonthAction),
            )
          : null,
    );
  }
}

class _HistoryList extends StatelessWidget {
  const new({required this.entries});

  final List<SalaryHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // Room under the last card for the button.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _MonthEntry(entry: entries[index]),
    );
  }
}

class _MonthEntry extends StatelessWidget {
  const new({required this.entry});

  final SalaryHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatter = context.moneyFormatter;
    final months = context.monthFormatter;
    final month = entry.month.month;
    final monthName = months.format(month);
    final payments = entry.result.payments;

    if (payments.length == 1) {
      return _EntryRow(
        title: monthName,
        caption: l10n.salaryTotalAfterTax,
        amount: formatter.format(entry.result.totalAfterTax),
        onTap: () => _open(context),
      );
    }

    final labels = [
      l10n.partPaidOn(
        part: l10n.partFirst,
        date: months.formatDay(month, entry.month.firstPayDay),
      ),
      l10n.partPaidOn(
        part: l10n.partSecond,
        date: months.formatDay(month.next, entry.month.secondPayDay),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
            child: Text(
              monthName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        for (var i = 0; i < payments.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _EntryRow(
            title: labels[i],
            amount: formatter.format(payments[i]),
            onTap: () => _open(context),
          ),
        ],
      ],
    );
  }

  Future<void> _open(BuildContext context) async {
    final bloc = context.read<SalaryHistoryBloc>();
    final l10n = context.l10n;

    final outcome = await context.push<SalaryEditOutcome>(
      AppRoutes.salaryMonthPath(entry.month.month),
    );
    bloc.add(const SalaryHistoryRefreshed());

    final message = switch (outcome) {
      SalaryEditOutcome.saved => l10n.monthSaved,
      SalaryEditOutcome.deleted => l10n.monthDeleted,
      null => null,
    };
    if (message != null && context.mounted) {
      showSuccessSnackBar(context, message);
    }
  }
}

/// A tappable tonal card: a title, and the amount at the end with an optional
/// caption under it.
class _EntryRow extends StatelessWidget {
  const new({
    required this.title,
    required this.amount,
    required this.onTap,
    this.caption,
  });

  final String title;
  final String? caption;

  /// The amount, already formatted.
  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
              child: LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    Expanded(
                      child: Text(title, style: theme.textTheme.bodyLarge),
                    ),
                    const SizedBox(width: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.55,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            amount,
                            style: theme.textTheme.titleMedium?.amount,
                            textAlign: TextAlign.end,
                          ),
                          if (caption != null)
                            Text(
                              caption!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.end,
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
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

class _HistorySkeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < 4; i++) ...[
            const SkeletonBox(),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
