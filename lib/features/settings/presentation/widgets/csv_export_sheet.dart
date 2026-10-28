import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/date_field.dart';
import 'package:money_scribe/features/settings/bloc/csv_export_bloc.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';

/// ST-7: the bottom sheet that chooses what to export as CSV and for which
/// days. Closes with what to export when Export is pressed (the password
/// dialog, ST-7b, makes the file), or with `null` when dismissed.
Future<CsvExportRequest?> showCsvExportSheet(BuildContext context) {
  final clock = context.read<Clock>();

  return showModalBottomSheet<CsvExportRequest>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Over the navigation bar too, which stays dimmed and inactive.
    useRootNavigator: true,
    builder: (sheetContext) => BlocProvider(
      create: (_) => CsvExportBloc(now: clock.now),
      child: _CsvExportSheet(today: clock.now()),
    ),
  );
}

class _CsvExportSheet extends StatelessWidget {
  const new({required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocConsumer<CsvExportBloc, CsvExportState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == CsvExportStatus.chosen,
      listener: (context, state) => Navigator.of(context).pop(state.request),
      builder: (context, state) {
        final bloc = context.read<CsvExportBloc>();
        // A chip stands for one or more kinds: the accounts and the custom
        // categories are one, because a restore needs both.
        final kinds = {
          l10n.csvKindSetup: const {
            CsvDataKind.accounts,
            CsvDataKind.categories,
          },
          l10n.transactionsTitle: const {CsvDataKind.transactions},
          l10n.debtsTitle: const {CsvDataKind.debts},
          l10n.csvKindSalaryMonths: const {CsvDataKind.salaryMonths},
        };
        final periods = {
          CsvPeriod.allTime: l10n.csvPeriodAllTime,
          CsvPeriod.thisYear: l10n.csvPeriodThisYear,
          CsvPeriod.custom: l10n.csvPeriodCustom,
        };

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.exportCsvTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.csvWhatToExport,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final MapEntry(key: label, value: chipKinds)
                        in kinds.entries)
                      FilterChip(
                        label: Text(label),
                        selected: state.kinds.containsAll(chipKinds),
                        onSelected: (_) => bloc.add(
                          chipKinds.length == 1
                              ? CsvKindToggled(chipKinds.single)
                              : CsvKindsToggled(chipKinds),
                        ),
                      ),
                  ],
                ),
                if (state.kinds.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.csvChooseKind,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.filterPeriod,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final MapEntry(key: period, value: label)
                        in periods.entries)
                      ChoiceChip(
                        label: Text(label),
                        selected: state.period == period,
                        showCheckmark: false,
                        onSelected: (_) => bloc.add(CsvPeriodSelected(period)),
                      ),
                  ],
                ),
                if (state.kinds.contains(CsvDataKind.accounts) ||
                    state.kinds.contains(CsvDataKind.categories)) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.csvPeriodNotForSetup,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (state.period == CsvPeriod.custom) ...[
                  const SizedBox(height: 16),
                  DateField(
                    label: l10n.fromLabel,
                    value: state.from,
                    today: today,
                    onChanged: (day) =>
                        bloc.add(CsvDatesChosen(from: day, to: state.to)),
                  ),
                  const SizedBox(height: 16),
                  DateField(
                    label: l10n.toLabel,
                    value: state.to,
                    today: today,
                    onChanged: (day) =>
                        bloc.add(CsvDatesChosen(from: state.from, to: day)),
                  ),
                  if (state.hasReversedDates) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.csvDatesReversed,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                Text(
                  l10n.csvSeveralKindsZip,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancelAction),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: state.canExport
                          ? () => bloc.add(const CsvExportRequested())
                          : null,
                      child: Text(l10n.exportAction),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
