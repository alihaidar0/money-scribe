import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/confirm_dialogs.dart';
import 'package:money_scribe/core/widgets/failure_snack_bar.dart';
import 'package:money_scribe/core/widgets/icon_circle.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/core/widgets/success_snack_bar.dart';
import 'package:money_scribe/features/sessions/bloc/sessions_bloc.dart';
import 'package:money_scribe/features/sessions/domain/device_session.dart';
import 'package:money_scribe/features/sessions/domain/sessions_repository.dart';
import 'package:money_scribe/features/sessions/presentation/widgets/revoke_others_dialog.dart';
import 'package:money_scribe/features/sessions/presentation/widgets/session_details_sheet.dart';
import 'package:money_scribe/features/sessions/presentation/widgets/session_rows.dart';

/// ST-12 and ST-12b to ST-12e: the devices the account is signed in on. The
/// Active tab lists them and signs the others out; the Previous tab lists the
/// sessions that ended in the last 90 days, grouped by device. A row opens the
/// details, where another device's session can be ended.
class SessionsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SessionsBloc(repository: context.read<SessionsRepository>())
            ..add(const SessionsStarted()),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<SessionsBloc>();

    return MultiBlocListener(
      listeners: [
        BlocListener<SessionsBloc, SessionsState>(
          listenWhen: (previous, current) =>
              previous.endedCount != current.endedCount,
          listener: (context, state) =>
              showSuccessSnackBar(context, l10n.sessionEndedSnack),
        ),
        BlocListener<SessionsBloc, SessionsState>(
          listenWhen: (previous, current) =>
              previous.failedAction != current.failedAction &&
              current.failedAction != null,
          listener: (context, state) {
            final action = state.failedAction;
            if (action == null) return;
            showFailureSnackBar(
              context,
              l10n.sessionEndFailed,
              onRetry: () => bloc.add(action),
            );
          },
        ),
      ],
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.sessionsTitle),
            bottom: TabBar.secondary(
              onTap: (index) => bloc.add(
                SessionsTabSelected(
                  index == 0 ? SessionsTab.active : SessionsTab.previous,
                ),
              ),
              tabs: [
                Tab(text: l10n.sessionsActiveTab),
                Tab(text: l10n.sessionsPreviousTab),
              ],
            ),
          ),
          body: const _Body(),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SessionsBloc>();
    final state = context.watch<SessionsBloc>().state;
    final l10n = context.l10n;

    if (state.tab == SessionsTab.active) {
      return switch (state.status) {
        SessionsStatus.loading => const _Skeleton(),
        SessionsStatus.noConnection => FailureView(
          kind: FailureKind.noConnection,
          onRetry: () => bloc.add(const SessionsRetried()),
        ),
        SessionsStatus.failure => FailureView(
          kind: FailureKind.error,
          errorTitle: l10n.sessionsLoadFailed,
          onRetry: () => bloc.add(const SessionsRetried()),
        ),
        SessionsStatus.ready => _ActiveList(state: state),
      };
    }
    return switch (state.previousStatus) {
      PreviousStatus.idle || PreviousStatus.loading => const _Skeleton(),
      PreviousStatus.noConnection => FailureView(
        kind: FailureKind.noConnection,
        onRetry: () => bloc.add(const SessionsRetried()),
      ),
      PreviousStatus.failure => FailureView(
        kind: FailureKind.error,
        errorTitle: l10n.sessionsLoadFailed,
        onRetry: () => bloc.add(const SessionsRetried()),
      ),
      PreviousStatus.ready when state.previous.isEmpty => const _NoPrevious(),
      PreviousStatus.ready => _PreviousList(state: state),
    };
  }
}

/// Opens the details of [session], and asks to confirm when the person chose
/// to end it.
Future<void> _open(BuildContext context, DeviceSession session) async {
  final bloc = context.read<SessionsBloc>();
  final l10n = context.l10n;
  final end = await showSessionDetailsSheet(context, session: session);
  if (end != true || !context.mounted) return;
  final confirmed = await confirmDestructive(
    context,
    title: l10n.sessionEndDialogTitle,
    message: l10n.sessionEndDialogMessage(device: session.deviceName),
    confirmLabel: l10n.sessionEndConfirm,
  );
  if (confirmed) bloc.add(SessionEndConfirmed(session.id));
}

class _ActiveList extends StatelessWidget {
  const new({required this.state});

  final SessionsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final today = context.read<Clock>().now();
    final others = state.others;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final session in state.active) ...[
          ActiveSessionRow(
            session: session,
            today: today,
            onTap: () => unawaited(_open(context, session)),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        Text(
          l10n.sessionsUnrecognised,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (others.isNotEmpty) ...[
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
            onPressed: () => unawaited(_signOutOthers(context, others.length)),
            child: Text(l10n.sessionsSignOutOthers),
          ),
        ],
      ],
    );
  }

  Future<void> _signOutOthers(BuildContext context, int count) async {
    final bloc = context.read<SessionsBloc>();
    final l10n = context.l10n;
    final result = await showRevokeOthersDialog(context, count: count);
    if (result == null || !context.mounted) return;
    showSuccessSnackBar(
      context,
      l10n.revokedOthersSnack(count: result.sessionsEnded),
    );
    bloc.add(const SessionsRefreshed());
  }
}

class _PreviousList extends StatelessWidget {
  const new({required this.state});

  final SessionsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bloc = context.read<SessionsBloc>();
    final caption = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.sessionsPreviousCaption, style: caption),
        const SizedBox(height: 16),
        for (final group in state.previousGroups) ...[
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(group.deviceName, style: theme.textTheme.titleMedium),
            ),
          ),
          for (final session in group.sessions) ...[
            EndedSessionRow(
              session: session,
              onTap: () => unawaited(_open(context, session)),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],
        if (state.loadingMore)
          const Center(child: CircularProgressIndicator())
        else if (state.loadMoreFailed) ...[
          Text(l10n.sessionsMoreFailed, style: caption),
          TextButton(
            onPressed: () => bloc.add(const PreviousSessionsMoreRequested()),
            child: Text(l10n.tryAgain),
          ),
        ] else if (state.previousNext != null)
          Center(
            child: TextButton(
              onPressed: () => bloc.add(const PreviousSessionsMoreRequested()),
              child: Text(l10n.sessionsShowMore),
            ),
          ),
        const SizedBox(height: 8),
        Text(l10n.sessionsPreviousFooter, style: caption),
      ],
    );
  }
}

/// ST-14: the Previous tab when no session ended in the last 90 days.
class _NoPrevious extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconCircle(icon: LucideIcons.history),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  l10n.sessionsPreviousEmpty,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.sessionsPreviousEmptyMessage,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ST-14: grey blocks where the sessions will be.
class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < 3; i++) ...[
            const SkeletonBox(height: 88),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
