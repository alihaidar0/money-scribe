import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/routing/navigation_extensions.dart';
import 'package:money_scribe/core/widgets/pinned_button_bar.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/settings/bloc/csv_import_bloc.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer_repository.dart';

/// ST-8 and ST-8b: import a CSV file. The system file picker opens first and
/// takes a `.csv` or a `.zip` file. The chosen file is read and checked: a
/// file that cannot be imported says why, and one that can shows the server's
/// estimate of what it would import. Import adds its rows, with the progress;
/// afterwards the screen says how many rows were imported and why each skipped
/// row was skipped.
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

class _CsvImportView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<CsvImportBloc>();
    final state = context.watch<CsvImportBloc>().state;

    final bottomBar = switch (state.status) {
      CsvImportStatus.checking ||
      CsvImportStatus.ready ||
      CsvImportStatus.importing => PinnedButtonBar(
        label: l10n.csvImportAction,
        isBusy: state.status == CsvImportStatus.importing,
        onPressed: state.status == CsvImportStatus.ready
            ? () => bloc.add(const CsvImportConfirmed())
            : null,
      ),
      CsvImportStatus.imported => PinnedButtonBar(
        label: l10n.doneAction,
        onPressed: () => context.popOrGo(AppRoutes.settings),
      ),
      _ => null,
    };

    void retry() => bloc.add(state.failedAction ?? const CsvImportStarted());

    return Scaffold(
      appBar: AppBar(title: Text(l10n.importCsvTitle)),
      body: switch (state.status) {
        CsvImportStatus.choosing => const _Skeleton(),
        CsvImportStatus.noFile => StateView(
          icon: LucideIcons.fileText,
          title: l10n.csvNoFileTitle,
          message: l10n.csvNoFileMessage,
          actionLabel: l10n.csvChooseFile,
          filledAction: true,
          onAction: () => bloc.add(const CsvFileRequested()),
        ),
        CsvImportStatus.fileProblem => StateView(
          icon: LucideIcons.circleAlert,
          title: l10n.csvFileProblemTitle,
          message: _fileIssueText(l10n, state),
          actionLabel: l10n.csvChooseAnotherFile,
          filledAction: true,
          onAction: () => bloc.add(const CsvFileRequested()),
        ),
        CsvImportStatus.noConnection => FailureView(
          kind: FailureKind.noConnection,
          onRetry: retry,
        ),
        CsvImportStatus.unavailable => FailureView(
          kind: FailureKind.unavailable,
          onRetry: retry,
        ),
        CsvImportStatus.failure => FailureView(
          kind: FailureKind.error,
          errorTitle: l10n.csvImportFailed,
          onRetry: retry,
        ),
        CsvImportStatus.checking ||
        CsvImportStatus.ready ||
        CsvImportStatus.importing => _Chosen(state: state),
        CsvImportStatus.imported => _Result(result: state.result!),
      },
      bottomNavigationBar: bottomBar,
    );
  }

  static String _fileIssueText(AppLocalizations l10n, CsvImportState state) {
    return switch (state.fileIssue) {
      CsvFileIssue.unknownColumns => l10n.csvFileUnknownColumns,
      CsvFileIssue.noRows => l10n.csvFileNoRows,
      CsvFileIssue.tooManyRows => l10n.csvFileTooManyRows(
        limit: state.fileLimit ?? 0,
      ),
      CsvFileIssue.tooLarge => l10n.csvFileTooLarge,
      CsvFileIssue.unreadable || null => l10n.csvFileUnreadable,
    };
  }
}

/// A page of the import: a column that scrolls, centred and not too wide.
class _Page extends StatelessWidget {
  const new({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: children);
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

/// ST-8: the chosen file, and what the check found or how far the import
/// is.
class _Chosen extends StatelessWidget {
  const new({required this.state});

  final CsvImportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final file = state.file!;
    final estimate = state.estimate;
    final busy = state.status != CsvImportStatus.ready;

    final (icon, status) = switch (state.status) {
      CsvImportStatus.checking => (LucideIcons.hourglass, l10n.csvChecking),
      CsvImportStatus.importing => (
        LucideIcons.upload,
        l10n.csvImportProgress(done: state.rowsDone, total: file.rows),
      ),
      _ => (
        estimate == null || estimate.skipped == 0
            ? LucideIcons.circleCheck
            : LucideIcons.triangleAlert,
        l10n.csvImportEstimate(
          imported: estimate?.imported ?? 0,
          problems: estimate?.skipped ?? 0,
        ),
      ),
    };

    return _Page(
      children: [
        _InfoCard(
          icon: LucideIcons.fileText,
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
        Semantics(
          liveRegion: true,
          container: true,
          child: _InfoCard(
            icon: icon,
            background: colors.secondaryContainer,
            foreground: colors.onSecondaryContainer,
            child: Text(
              status,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
          ),
        ),
        if (state.status == CsvImportStatus.ready && file.crowdedDays > 0) ...[
          const SizedBox(height: 12),
          _InfoCard(
            icon: LucideIcons.info,
            child: Text(
              l10n.csvCrowdedDays(days: file.crowdedDays),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
        if (state.status == CsvImportStatus.ready && estimate != null)
          _ProblemList(result: estimate),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: busy
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
            icon: skipped ? LucideIcons.triangleAlert : LucideIcons.circleCheck,
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
        _ProblemList(result: result),
      ],
    );
  }
}

/// The rows that were (or would be) skipped, each with why. A file of several
/// kinds says the kind of each row.
class _ProblemList extends StatelessWidget {
  const new({required this.result});

  final CsvImportResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final problem in result.problems)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    LucideIcons.circleAlert,
                    size: 20,
                    color: colors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _text(l10n, problem),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _text(AppLocalizations l10n, CsvProblem problem) {
    final reason = switch (problem.reason) {
      CsvProblemReason.missingDate => l10n.csvReasonMissingDate,
      CsvProblemReason.invalidAmount => l10n.csvReasonInvalidAmount,
      CsvProblemReason.duplicate => l10n.csvReasonDuplicate,
      CsvProblemReason.unknownCategory => l10n.csvReasonUnknownCategory,
      CsvProblemReason.unknownAccount => l10n.csvReasonUnknownAccount,
      CsvProblemReason.limitReached => l10n.csvReasonLimitReached,
      CsvProblemReason.nameTaken => l10n.csvReasonNameTaken,
      CsvProblemReason.missingIcon => l10n.csvReasonMissingIcon,
      CsvProblemReason.other => l10n.csvReasonOther,
    };
    if (!result.spansParts) {
      return l10n.csvProblemRow(row: problem.row, reason: reason);
    }
    final part = switch (problem.kind) {
      CsvDataKind.accounts => l10n.accountsTitle,
      CsvDataKind.categories => l10n.categoriesTitle,
      CsvDataKind.transactions => l10n.transactionsTitle,
      CsvDataKind.debts => l10n.debtsTitle,
      CsvDataKind.salaryMonths => l10n.csvKindSalaryMonths,
    };
    return l10n.csvProblemPartRow(part: part, row: problem.row, reason: reason);
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
