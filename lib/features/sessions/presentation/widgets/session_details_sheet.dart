import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/features/sessions/domain/device_session.dart';
import 'package:money_scribe/features/sessions/presentation/session_text.dart';

/// ST-12c: the details of a session in a bottom sheet. It closes with `true`
/// when the person pressed "End this session" (only offered for the session
/// of another device that is still active), and with `null` otherwise.
Future<bool?> showSessionDetailsSheet(
  BuildContext context, {
  required DeviceSession session,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Over the navigation bar too.
    useRootNavigator: true,
    builder: (_) => _SessionDetails(session: session),
  );
}

class _SessionDetails extends StatelessWidget {
  const new({required this.session});

  final DeviceSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final method = l10n.signInMethodText(session.signInMethod);
    final endedAt = session.endedAt;
    final network = session.network;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                session.deviceName,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.sessionSystemAndApp(
                system: session.osVersion,
                app: session.appVersion,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (method != null) _Fact(l10n.sessionMethodLabel, method),
            _Fact(
              l10n.sessionDetailSignedIn,
              context.sessionMoment(session.signedInAt),
            ),
            _Fact(
              l10n.sessionDetailLastActive,
              context.sessionMoment(session.lastActiveAt),
            ),
            if (!session.isEnded)
              _Fact(
                l10n.sessionDetailEnds,
                context.sessionDay(session.expiresAt),
              ),
            if (network != null) _Fact(l10n.sessionDetailNetwork, network),
            const SizedBox(height: 16),
            if (session.isEnded)
              Text(
                l10n.sessionEndedNote(
                  when: endedAt == null ? '' : context.sessionMoment(endedAt),
                  reason: l10n.endReasonText(session.endReason),
                ),
                style: theme.textTheme.bodyMedium,
              )
            else if (session.isCurrent)
              Text(l10n.sessionCurrentNote, style: theme.textTheme.bodyMedium)
            else ...[
              Text(
                l10n.sessionEndsFingerprintNote,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.sessionEndAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A label and its value on one row, the value wrapping when it is long.
class _Fact extends StatelessWidget {
  const new(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
