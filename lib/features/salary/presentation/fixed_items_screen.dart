import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';
import 'package:money_scribe/core/theme/money_colors.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/failure_snack_bar.dart';
import 'package:money_scribe/core/widgets/icon_circle.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/core/widgets/top_level_screen.dart';
import 'package:money_scribe/core/widgets/wide_frame.dart';
import 'package:money_scribe/features/salary/bloc/fixed_items_bloc.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_repository.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';
import 'package:money_scribe/features/salary/presentation/widgets/fixed_item_sheet.dart';
import 'package:money_scribe/features/salary/presentation/widgets/fixed_items_summary_card.dart';
import 'package:money_scribe/features/salary/presentation/widgets/salary_history_button.dart';
import 'package:money_scribe/features/salary/presentation/widgets/salary_section_switch.dart';

/// FIX-1 to FIX-6: the recurring income and costs of a month, the second
/// segment of the Salary screen. It shows [month], or the month of today when
/// the Salary screen does not send one.
///
/// With one payment a month the items are one list; with two payments each
/// belongs to a part and the person chooses which part to see. Under the list
/// is the balance the pay leaves after them. Items are added and changed in a
/// bottom sheet, and deleting asks first.
class FixedItemsScreen extends StatelessWidget {
  const new({this.month, super.key});

  final YearMonth? month;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Another month is another screen.
      key: ValueKey(month),
      create: (context) => FixedItemsBloc(
        fixedItems: context.read<FixedItemsRepository>(),
        salary: context.read<SalaryRepository>(),
        month: month ?? YearMonth.fromDate(context.read<Clock>().now()),
      )..add(const FixedItemsStarted()),
      child: const _FixedItemsView(),
    );
  }
}

class _FixedItemsView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return BlocListener<FixedItemsBloc, FixedItemsState>(
      listenWhen: (previous, current) =>
          previous.failedAction != current.failedAction &&
          current.failedAction != null,
      listener: (context, state) {
        final action = state.failedAction;
        if (action == null) return;
        showFailureSnackBar(
          context,
          action is FixedItemDeleted
              ? context.l10n.couldNotDelete
              : context.l10n.couldNotSave,
          onRetry: () => context.read<FixedItemsBloc>().add(action),
        );
      },
      child: TopLevelScreen(
        title: context.l10n.salaryTitle,
        actions: const [SalaryHistoryButton()],
        body: const _Body(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FixedItemsBloc>();
    final month = context.select<FixedItemsBloc, YearMonth>(
      (bloc) => bloc.state.month,
    );
    final status = context.select<FixedItemsBloc, FixedItemsStatus>(
      (bloc) => bloc.state.status,
    );
    final showParts = context.select<FixedItemsBloc, bool>(
      (bloc) =>
          bloc.state.status == FixedItemsStatus.ready && bloc.state.twoPayments,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SalarySectionSwitch(
            selected: SalarySection.fixedItems,
            month: month,
          ),
        ),
        if (showParts)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _PartSwitch(),
          ),
        Expanded(
          child: switch (status) {
            FixedItemsStatus.loading => const _Skeleton(),
            FixedItemsStatus.noConnection => FailureView(
              kind: FailureKind.noConnection,
              onRetry: () => bloc.add(const FixedItemsRetried()),
            ),
            FixedItemsStatus.failure => FailureView(
              kind: FailureKind.error,
              onRetry: () => bloc.add(const FixedItemsRetried()),
            ),
            FixedItemsStatus.ready => const _Content(),
          },
        ),
      ],
    );
  }
}

/// The segmented control "Part 1 | Part 2" of a month paid in two payments.
class _PartSwitch extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final part = context.select<FixedItemsBloc, FixedItemPart>(
      (bloc) => bloc.state.part,
    );

    return SizedBox(
      width: double.infinity,
      child: PillSegmentedButton<FixedItemPart>(
        segments: [
          ButtonSegment(
            value: FixedItemPart.first,
            label: Text(l10n.partFirst),
          ),
          ButtonSegment(
            value: FixedItemPart.second,
            label: Text(l10n.partSecond),
          ),
        ],
        selected: {part},
        onSelectionChanged: (selection) => context.read<FixedItemsBloc>().add(
          FixedItemsPartSelected(selection.first),
        ),
      ),
    );
  }
}

/// Opens the sheet that adds an item to what the screen shows.
Future<void> _addItem(BuildContext context) async {
  final bloc = context.read<FixedItemsBloc>();
  final state = bloc.state;
  final result = await showFixedItemSheet(
    context,
    currency: state.currency,
    twoPayments: state.twoPayments,
    part: state.part,
  );
  if (result is FixedItemSheetSaved) bloc.add(FixedItemAdded(result.draft));
}

/// Opens the sheet that changes or deletes [item].
Future<void> _editItem(BuildContext context, FixedItem item) async {
  final bloc = context.read<FixedItemsBloc>();
  final state = bloc.state;
  final result = await showFixedItemSheet(
    context,
    currency: state.currency,
    twoPayments: state.twoPayments,
    part: state.part,
    item: item,
  );
  switch (result) {
    case FixedItemSheetSaved(:final draft):
      bloc.add(FixedItemChanged(item.id, draft));
    case FixedItemSheetDeleted():
      bloc.add(FixedItemDeleted(item.id));
    case null:
      break;
  }
}

class _Content extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<FixedItemsBloc>().state;
    final items = state.shownItems;

    if (items.isEmpty) {
      return StateView(
        icon: Icons.autorenew,
        title: l10n.fixedItemsEmptyTitle,
        message: l10n.fixedItemsEmptyMessage,
        actionLabel: l10n.addItemAction,
        filledAction: true,
        onAction: () => _addItem(context),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: FrameWidth.regular.value),
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ListView.separated(
                      // Room under the last row for the button.
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) => _ItemRow(
                        item: items[index],
                        onEdit: () => _editItem(context, items[index]),
                      ),
                    ),
                    PositionedDirectional(
                      end: 16,
                      bottom: 16,
                      child: FloatingActionButton.extended(
                        heroTag: null,
                        onPressed: () => _addItem(context),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.addItemAction),
                      ),
                    ),
                  ],
                ),
              ),
              // Scrolls when a large text size would take most of the screen.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * 0.5,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: FixedItemsSummaryCard(
                    summary: state.summary,
                    items: items,
                    twoPayments: state.twoPayments,
                    part: state.part,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tonal row: a soft icon circle, the name, the signed amount and the edit
/// button. Income is green with a plus and an arrow in, an expense is red with
/// a minus and an arrow out, so the meaning never rests on colour alone.
class _ItemRow extends StatelessWidget {
  const new({required this.item, required this.onEdit});

  final FixedItem item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final income = item.kind == FixedItemKind.income;
    final money = income
        ? context.moneyColors.income
        : context.moneyColors.expense;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 4, 8),
          child: Row(
            children: [
              IconCircle(
                icon: income ? Icons.south_west : Icons.north_east,
                size: 40,
                background: money.container,
                foreground: money.onContainer,
              ),
              const SizedBox(width: 12),
              // The name and the amount share a line when they fit; when they
              // do not, the amount goes under the name, so neither is cut.
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    Text(item.name, style: theme.textTheme.bodyLarge),
                    Text(
                      context.moneyFormatter.formatSigned(item.signedAmount),
                      style: theme.textTheme.titleMedium?.amount.copyWith(
                        color: money.color,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: context.l10n.editFixedItemTooltip(name: item.name),
                onPressed: onEdit,
              ),
            ],
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
          for (var i = 0; i < 3; i++) ...[
            const SkeletonBox(),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          const SkeletonBox(height: 120),
        ],
      ),
    );
  }
}
