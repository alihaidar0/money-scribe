import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/icon_circle.dart';
import 'package:money_scribe/features/sessions/domain/device_session.dart';
import 'package:money_scribe/features/sessions/presentation/session_text.dart';

/// A tonal row of a session that is active: the kind of device, its name (and
/// "This device" for the one in use), the system and the app, when it signed in
/// and when it was last used. It opens the details.
class ActiveSessionRow extends StatelessWidget {
  const new({
    required this.session,
    required this.today,
    required this.onTap,
    super.key,
  });

  final DeviceSession session;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final signedIn = l10n.sessionSignedInAt(
      when: context.sessionDay(session.signedInAt),
    );
    final lastActive = l10n.sessionLastActiveAt(
      when: context.sessionRecently(session.lastActiveAt, today: today),
    );

    return Semantics(
      button: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
              child: Row(
                children: [
                  IconCircle(
                    icon: context.sessionIcon(session.platform),
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              session.deviceName,
                              style: theme.textTheme.bodyLarge,
                            ),
                            if (session.isCurrent) const _ThisDeviceBadge(),
                          ],
                        ),
                        Text(
                          l10n.sessionSystemAndApp(
                            system: session.osVersion,
                            app: session.appVersion,
                          ),
                          style: secondary,
                        ),
                        Text('$signedIn · $lastActive', style: secondary),
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
    );
  }
}

/// A row of a session that ended, under the name of its device: when it signed
/// in, and when and why it ended. It opens the details, which are read only.
class EndedSessionRow extends StatelessWidget {
  const new({required this.session, required this.onTap, super.key});

  final DeviceSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final endedAt = session.endedAt;

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
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sessionSignedInAt(
                            when: context.sessionMoment(session.signedInAt),
                          ),
                          style: theme.textTheme.bodyLarge,
                        ),
                        Text(
                          l10n.sessionEndedOn(
                            when: endedAt == null
                                ? ''
                                : context.sessionMoment(endedAt),
                            reason: l10n.endReasonText(session.endReason),
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThisDeviceBadge extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          context.l10n.sessionThisDevice,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
