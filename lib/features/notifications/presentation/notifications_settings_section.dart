import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_scribe/core/clipboard/text_clipboard.dart';
import 'package:money_scribe/core/environment/app_environment_scope.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/features/notifications/bloc/notifications_bloc.dart';
import 'package:money_scribe/features/notifications/domain/notification_permission.dart';
import 'package:money_scribe/features/notifications/domain/push_messaging_repository.dart';

/// The notification settings on the Settings screen: the permission and, in
/// staging builds, a way to copy the push token for test messages. Shows
/// nothing where push is not available.
class NotificationsSettingsSection extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    // Read here, not in `create`, which runs once and may not listen.
    final canCopyPushToken = !AppEnvironmentScope.of(context).isProduction;

    return BlocProvider(
      create: (context) => NotificationsBloc(
        pushMessaging: context.read<PushMessagingRepository>(),
        clipboard: context.read<TextClipboard>(),
        canCopyPushToken: canCopyPushToken,
      )..add(const NotificationsStarted()),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    // The snackbar is a one-time effect of the copy result, not part of the
    // layout, so a listener shows it.
    return BlocListener<NotificationsBloc, NotificationsState>(
      listenWhen: (previous, current) =>
          previous.tokenCopy != current.tokenCopy,
      listener: _showTokenCopyResult,
      child: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state.status == NotificationsStatus.unavailable) {
            return const SizedBox.shrink();
          }
          final l10n = context.l10n;

          return Column(
            children: [
              ListTile(
                title: Text(
                  l10n.notificationsSectionTitle,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              ListTile(
                title: Text(l10n.notificationsPermissionTitle),
                subtitle: Text(_status(l10n, state)),
                trailing: _canAsk(state)
                    ? FilledButton.tonal(
                        onPressed: () => context.read<NotificationsBloc>().add(
                          const NotificationPermissionRequested(),
                        ),
                        child: Text(l10n.notificationsAllow),
                      )
                    : null,
              ),
              if (state.canCopyPushToken)
                ListTile(
                  title: Text(l10n.pushTokenCopy),
                  subtitle: Text(l10n.pushTokenCopyHint),
                  leading: const Icon(Icons.content_copy_outlined),
                  onTap: () => context.read<NotificationsBloc>().add(
                    const PushTokenCopyRequested(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  bool _canAsk(NotificationsState state) {
    return state.status == NotificationsStatus.ready &&
        state.permission == NotificationPermission.notGranted;
  }

  String _status(AppLocalizations l10n, NotificationsState state) {
    return switch (state.status) {
      NotificationsStatus.loading || NotificationsStatus.unavailable => '',
      NotificationsStatus.failure => l10n.notificationsStatusError,
      NotificationsStatus.ready => switch (state.permission) {
        NotificationPermission.granted => l10n.notificationsStatusGranted,
        NotificationPermission.notGranted => l10n.notificationsStatusNotGranted,
        NotificationPermission.blocked => l10n.notificationsStatusBlocked,
      },
    };
  }

  void _showTokenCopyResult(BuildContext context, NotificationsState state) {
    final l10n = context.l10n;
    final message = switch (state.tokenCopy) {
      PushTokenCopyStatus.copied => l10n.pushTokenCopied,
      PushTokenCopyStatus.missing => l10n.pushTokenMissing,
      PushTokenCopyStatus.failure => l10n.pushTokenCopyFailed,
      PushTokenCopyStatus.idle || PushTokenCopyStatus.copying => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
