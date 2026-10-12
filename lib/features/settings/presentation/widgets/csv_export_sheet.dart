import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/button_spinner.dart';
import 'package:money_scribe/core/widgets/date_field.dart';
import 'package:money_scribe/core/widgets/message_banner.dart';
import 'package:money_scribe/features/settings/bloc/csv_export_bloc.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer_repository.dart';

/// ST-7: the bottom sheet that chooses what to export as CSV and for which
/// days, and makes the file. Closes with `true` once the file is made, or with
/// `null` when dismissed.
Future<bool?> showCsvExportSheet(BuildContext context) {
  final repository = context.read<CsvTransferRepository>();
  final clock = context.read<Clock>();

  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Over the navigation bar too, which stays dimmed and inactive.
    useRootNavigator: true,
    builder: (sheetContext) => BlocProvider(
      create: (_) => CsvExportBloc(repository: repository, now: clock.now),
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
          current.status == CsvExportStatus.exported,
      listener: (context, state) => Navigator.of(context).pop(true),
      builder: (context, state) {
        final bloc = context.read<CsvExportBloc>();
        final isBusy = state.status == CsvExportStatus.exporting;
        final kinds = {
          CsvDataKind.transactions: l10n.transactionsTitle,
          CsvDataKind.debts: l10n.debtsTitle,
          CsvDataKind.salaryMonths: l10n.csvKindSalaryMonths,
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
                if (state.status == CsvExportStatus.noConnection ||
                    state.status == CsvExportStatus.failure) ...[
                  MessageBanner(
                    icon: Icons.error_outline,
                    text: l10n.couldNotExport,
                  ),
                  const SizedBox(height: 16),
                ],
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
                    for (final MapEntry(key: kind, value: label)
                        in kinds.entries)
                      FilterChip(
                        label: Text(label),
                        selected: state.kinds.contains(kind),
                        onSelected: isBusy
                            ? null
                            : (_) => bloc.add(CsvKindToggled(kind)),
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
                        onSelected: isBusy
                            ? null
                            : (_) => bloc.add(CsvPeriodSelected(period)),
                      ),
                  ],
                ),
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
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isBusy
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(l10n.cancelAction),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: state.canExport && !isBusy
                          ? () => bloc.add(const CsvExportRequested())
                          : null,
                      child: isBusy
                          ? const ButtonSpinner()
                          : Text(l10n.exportAction),
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
