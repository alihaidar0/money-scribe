import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/routing/navigation_extensions.dart';
import 'package:money_scribe/core/widgets/pinned_button_bar.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/settings/bloc/csv_import_bloc.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer_repository.dart';

/// ST-8 and ST-8b: import a CSV file. The system file picker opens first; the
/// chosen file is shown with a status, and Import adds its rows. Afterwards
/// the screen says how many rows were imported and lists those that were
/// skipped.
class CsvImportScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CsvImportBloc(repository: context.read<CsvTransferRepository>())
            ..add(const CsvImportStarted()),
      child: const _CsvImportView(),
    );
  }
}

/// The widest the page grows, so it stays readable on a wide screen.
const _maxContentWidth = 560.0;

class _CsvImportView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<CsvImportBloc>();
    final state = context.watch<CsvImportBloc>().state;

    Widget? bottomBar;
    if (state.status == CsvImportStatus.ready ||
        state.status == CsvImportStatus.importing) {
      bottomBar = PinnedButtonBar(
        label: l10n.csvImportAction,
        isBusy: state.status == CsvImportStatus.importing,
        onPressed: state.status == CsvImportStatus.ready
            ? () => bloc.add(const CsvImportConfirmed())
            : null,
      );
    } else if (state.status == CsvImportStatus.imported) {
      bottomBar = PinnedButtonBar(
        label: l10n.doneAction,
        onPressed: () => context.popOrGo(AppRoutes.settings),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.importCsvTitle)),
      body: switch (state.status) {
        CsvImportStatus.choosing => const _Skeleton(),
        CsvImportStatus.noFile => StateView(
          icon: Icons.description_outlined,
          title: l10n.csvNoFileTitle,
          message: l10n.csvNoFileMessage,
          actionLabel: l10n.csvChooseFile,
          filledAction: true,
          onAction: () => bloc.add(const CsvFileRequested()),
        ),
        CsvImportStatus.noConnection => FailureView(
          kind: FailureKind.noConnection,
          onRetry: () =>
              bloc.add(state.failedAction ?? const CsvImportStarted()),
        ),
        CsvImportStatus.failure => FailureView(
          kind: FailureKind.error,
          errorTitle: l10n.csvImportFailed,
          onRetry: () =>
              bloc.add(state.failedAction ?? const CsvImportStarted()),
        ),
        CsvImportStatus.ready || CsvImportStatus.importing => _Chosen(
          file: state.file!,
          isBusy: state.status == CsvImportStatus.importing,
        ),
        CsvImportStatus.imported => _Result(result: state.result!),
      },
      bottomNavigationBar: bottomBar,
    );
  }
}

/// A page of the import: a column that scrolls, centred and not too wide.
class _Page extends StatelessWidget {
  const new({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: ListView(padding: const EdgeInsets.all(16), children: children),
      ),
    );
  }
}

/// A tonal card with an icon in front of a text, for the file and its status.
class _InfoCard extends StatelessWidget {
  const new({
    required this.icon,
    required this.child,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final Widget child;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(icon, color: foreground ?? colors.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// ST-8: the chosen file and whether it can be imported.
class _Chosen extends StatelessWidget {
  const new({required this.file, required this.isBusy});

  final CsvFile file;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _Page(
      children: [
        _InfoCard(
          icon: Icons.description_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A file name reads from left to right in any language.
              Text(
                file.name,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                l10n.csvRowCount(rows: file.rows),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          icon: Icons.check_circle_outline,
          background: colors.secondaryContainer,
          foreground: colors.onSecondaryContainer,
          child: Text(
            l10n.csvReadyToImport(rows: file.rows),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSecondaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: isBusy
                ? null
                : () => context.read<CsvImportBloc>().add(
                    const CsvFileRequested(),
                  ),
            child: Text(l10n.csvChooseAnotherFile),
          ),
        ),
      ],
    );
  }
}

/// ST-8b: how the import went, and the rows that were skipped.
class _Result extends StatelessWidget {
  const new({required this.result});

  final CsvImportResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final skipped = result.skipped > 0;

    return _Page(
      children: [
        Semantics(
          liveRegion: true,
          container: true,
          child: _InfoCard(
            icon: skipped
                ? Icons.warning_amber_outlined
                : Icons.check_circle_outline,
            background: colors.secondaryContainer,
            foreground: colors.onSecondaryContainer,
            child: Text(
              l10n.csvImportFinished(
                imported: result.imported,
                skipped: result.skipped,
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
          ),
        ),
        for (final problem in result.problems)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.error_outline,
                    size: 20,
                    color: colors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(switch (problem.kind) {
                    CsvProblemKind.invalidAmount =>
                      l10n.csvProblemInvalidAmount(row: problem.row),
                    CsvProblemKind.missingDate => l10n.csvProblemMissingDate(
                      row: problem.row,
                    ),
                  }, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const SkeletonScope(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SkeletonBox(height: 72),
            SizedBox(height: 12),
            SkeletonBox(height: 56),
          ],
        ),
      ),
    );
  }
}
