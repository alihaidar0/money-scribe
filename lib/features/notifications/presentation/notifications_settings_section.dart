import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_scribe/app/environment/app_environment_provider.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/features/notifications/application/push_messaging_providers.dart';
import 'package:money_scribe/features/notifications/domain/notification_permission.dart';

/// The notification settings on the Settings screen: the permission and, in
/// staging builds, a way to copy the push token for test messages. Shows
/// nothing where push is not available.
class NotificationsSettingsSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(pushMessagingRepositoryProvider).isAvailable) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final permission = ref.watch(notificationPermissionControllerProvider);
    final showToken = !ref.watch(appEnvironmentProvider).isProduction;

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
          subtitle: Text(_status(l10n, permission)),
          trailing: permission.value == NotificationPermission.notGranted
              ? FilledButton.tonal(
                  onPressed: () => unawaited(
                    ref
                        .read(notificationPermissionControllerProvider.notifier)
                        .request(),
                  ),
                  child: Text(l10n.notificationsAllow),
                )
              : null,
        ),
        if (showToken)
          ListTile(
            title: Text(l10n.pushTokenCopy),
            subtitle: Text(l10n.pushTokenCopyHint),
            leading: const Icon(Icons.content_copy_outlined),
            onTap: () => unawaited(_copyToken(context, ref)),
          ),
      ],
    );
  }

  String _status(
    AppLocalizations l10n,
    AsyncValue<NotificationPermission> permission,
  ) {
    return switch (permission) {
      AsyncData(value: NotificationPermission.granted) =>
        l10n.notificationsStatusGranted,
      AsyncData(value: NotificationPermission.notGranted) =>
        l10n.notificationsStatusNotGranted,
      AsyncData(value: NotificationPermission.blocked) =>
        l10n.notificationsStatusBlocked,
      AsyncError() => l10n.notificationsStatusError,
      AsyncLoading() => '',
    };
  }

  Future<void> _copyToken(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final token = await ref.read(pushMessagingRepositoryProvider).token();
    if (token == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.pushTokenMissing)));
      return;
    }
    await Clipboard.setData(ClipboardData(text: token));
    messenger.showSnackBar(SnackBar(content: Text(l10n.pushTokenCopied)));
  }
}
