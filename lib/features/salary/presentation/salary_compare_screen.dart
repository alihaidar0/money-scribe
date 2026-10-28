import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/month_chip.dart';
import 'package:money_scribe/core/widgets/month_picker_sheet.dart';
import 'package:money_scribe/core/widgets/part_selector.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/salary/bloc/salary_compare_bloc.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_repository.dart';
import 'package:money_scribe/features/salary/domain/salary_comparison.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';
import 'package:money_scribe/features/salary/presentation/widgets/salary_compare_table.dart';

/// SAL-8 and SAL-9: two months side by side with the difference between them.
/// A month paid in two payments can also be compared part by part.
class SalaryCompareScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SalaryCompareBloc(
        repository: context.read<SalaryRepository>(),
        fixedItems: context.read<FixedItemsRepository>(),
        now: context.read<Clock>().now,
      )..add(const SalaryCompareStarted()),
      child: const _CompareView(),
    );
  }
}

class _CompareView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SalaryCompareBloc>();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.compareMonthsTitle)),
      body: BlocBuilder<SalaryCompareBloc, SalaryCompareState>(
        builder: (context, state) => switch (state.status) {
          SalaryCompareStatus.loading => const _CompareSkeleton(),
          SalaryCompareStatus.noConnection => FailureView(
            kind: FailureKind.noConnection,
            onRetry: () => bloc.add(const SalaryCompareRetried()),
          ),
          SalaryCompareStatus.failure => FailureView(
            kind: FailureKind.error,
            onRetry: () => bloc.add(const SalaryCompareRetried()),
          ),
          SalaryCompareStatus.ready => _CompareContent(state: state),
        },
      ),
    );
  }
}

class _CompareContent extends StatelessWidget {
  const new({required this.state});

  final SalaryCompareState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SalaryCompareBloc>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.hasParts) ...[
            PartSelector(
              selected: state.effectiveScope,
              onSelected: (scope) =>
                  bloc.add(SalaryCompareScopeSelected(scope)),
            ),
            const SizedBox(height: 16),
          ],
          _MonthPair(left: state.left, right: state.right),
          const SizedBox(height: 16),
          SalaryCompareTable(
            lines: state.lines,
            left: state.left,
            right: state.right,
          ),
        ],
      ),
    );
  }
}

/// The smallest a button is, which the swap button is.
const _swapButtonSize = 48.0;

/// The two month chips with the swap button between them: side by side when
/// each month fits on one line in half the width, otherwise one under the
/// other, so a month name never breaks across lines inside its chip.
class _MonthPair extends StatelessWidget {
  const new({required this.left, required this.right});

  final YearMonth left;
  final YearMonth right;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SalaryCompareBloc>();
    final leftChip = MonthChip(
      month: left,
      onPressed: () => _choose(context, CompareSide.left, left),
    );
    final rightChip = MonthChip(
      month: right,
      onPressed: () => _choose(context, CompareSide.right, right),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final widest = math.max(
          MonthChip.naturalWidth(context, left),
          MonthChip.naturalWidth(context, right),
        );
        final sideBySide = constraints.maxWidth >= 2 * widest + _swapButtonSize;
        final swap = IconButton(
          icon: Icon(
            sideBySide ? LucideIcons.arrowLeftRight : LucideIcons.arrowUpDown,
          ),
          tooltip: context.l10n.swapMonthsTooltip,
          onPressed: () => bloc.add(const SalaryCompareSwapped()),
        );

        return sideBySide
            ? Row(
                children: [
                  Expanded(child: Align(child: leftChip)),
                  swap,
                  Expanded(child: Align(child: rightChip)),
                ],
              )
            : Column(children: [leftChip, swap, rightChip]);
      },
    );
  }

  Future<void> _choose(
    BuildContext context,
    CompareSide side,
    YearMonth month,
  ) async {
    final bloc = context.read<SalaryCompareBloc>();
    final chosen = await showMonthPickerSheet(
      context,
      selected: month,
      last: YearMonth.fromDate(context.read<Clock>().now()),
    );
    if (chosen != null && chosen != month) {
      bloc.add(SalaryCompareMonthChosen(side, chosen));
    }
  }
}

class _CompareSkeleton extends StatelessWidget {
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
          SkeletonBox(height: 200),
        ],
      ),
    );
  }
}
