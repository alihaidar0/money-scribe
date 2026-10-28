import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/widgets/icon_circle.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/sessions/bloc/security_activity_bloc.dart';
import 'package:money_scribe/features/sessions/domain/security_event.dart';
import 'package:money_scribe/features/sessions/domain/sessions_repository.dart';
import 'package:money_scribe/features/sessions/presentation/session_text.dart';

/// ST-13: what happened to the account in the last 90 days, newest first,
/// under the day it happened. An old sign-in that was used again is a warning
/// with a way to change the password.
class SecurityActivityScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SecurityActivityBloc(repository: context.read<SessionsRepository>())
            ..add(const SecurityActivityStarted()),
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.securityActivityTitle)),
        body: const _Body(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SecurityActivityBloc>();
    final state = context.watch<SecurityActivityBloc>().state;
    final l10n = context.l10n;

    return switch (state.status) {
      SecurityActivityStatus.loading => const _Skeleton(),
      SecurityActivityStatus.noConnection => FailureView(
        kind: FailureKind.noConnection,
        onRetry: () => bloc.add(const SecurityActivityRetried()),
      ),
      SecurityActivityStatus.failure => FailureView(
        kind: FailureKind.error,
        errorTitle: l10n.securityActivityLoadFailed,
        onRetry: () => bloc.add(const SecurityActivityRetried()),
      ),
      SecurityActivityStatus.ready when state.events.isEmpty => const _Empty(),
      SecurityActivityStatus.ready => _Timeline(state: state),
    };
  }
}

class _Timeline extends StatelessWidget {
  const new({required this.state});

  final SecurityActivityState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bloc = context.read<SecurityActivityBloc>();
    final caption = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final days = context.dayFormatter;

    final children = <Widget>[];
    DateTime? currentDay;
    for (final event in state.entries) {
      final local = event.occurredAt.toLocal();
      if (currentDay == null || !days.isSameDay(currentDay, local)) {
        currentDay = local;
        children.add(
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                days.formatWithYear(local),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        );
      }
      children
        ..add(_EventTile(event: event))
        ..add(const SizedBox(height: 8));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...children,
        if (state.loadingMore)
          const Center(child: CircularProgressIndicator())
        else if (state.loadMoreFailed) ...[
          Text(l10n.sessionsMoreFailed, style: caption),
          TextButton(
            onPressed: () => bloc.add(const SecurityActivityMoreRequested()),
            child: Text(l10n.tryAgain),
          ),
        ] else if (state.next != null)
          Center(
            child: TextButton(
              onPressed: () => bloc.add(const SecurityActivityMoreRequested()),
              child: Text(l10n.sessionsShowMore),
            ),
          ),
        const SizedBox(height: 8),
        Text(l10n.securityActivityFooter, style: caption),
      ],
    );
  }
}

/// One entry: an icon, what happened, the facts under it, and the time. A
/// possible reuse of an old sign-in is a warning with a way to change the
/// password.
class _EventTile extends StatelessWidget {
  const new({required this.event});

  final SecurityEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final warning = event.type == SecurityEventType.tokenReuseDetected;
    final detail = l10n.eventDetail(event);
    final time = context.dayFormatter.formatTime(event.occurredAt.toLocal());
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: warning
          ? theme.colorScheme.onErrorContainer
          : theme.colorScheme.onSurfaceVariant,
    );

    return Material(
      color: warning
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconCircle(
              icon: l10n.eventIcon(event.type),
              size: 40,
              background: warning ? theme.colorScheme.error : null,
              foreground: warning ? theme.colorScheme.onError : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.eventTitle(event.type),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: warning
                          ? theme.colorScheme.onErrorContainer
                          : null,
                    ),
                  ),
                  if (warning) ...[
                    const SizedBox(height: 4),
                    Text(l10n.securityEventTokenReuseMessage, style: secondary),
                  ],
                  if (detail != null) Text(detail, style: secondary),
                  if (warning)
                    TextButton(
                      onPressed: () => context.push(AppRoutes.changePassword),
                      child: Text(l10n.changePasswordTitle),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              time,
              style: secondary?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ST-14: the activity of an account that has none yet.
class _Empty extends StatelessWidget {
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
              const IconCircle(icon: LucideIcons.shield),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  l10n.securityActivityEmpty,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.securityActivityEmptyMessage,
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

/// ST-14: grey blocks where the entries will be.
class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < 4; i++) ...[
            const SkeletonBox(height: 72),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
