import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/device/device_info.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/routing/navigation_extensions.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/failure_snack_bar.dart';
import 'package:money_scribe/core/widgets/icon_circle.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/core/widgets/success_snack_bar.dart';
import 'package:money_scribe/features/auth/bloc/device_key_list_bloc.dart';
import 'package:money_scribe/features/auth/domain/device_key.dart';
import 'package:money_scribe/features/auth/domain/device_key_repository.dart';
import 'package:money_scribe/features/auth/presentation/widgets/remove_phone_dialog.dart';

/// The phones whose fingerprint can sign the account in, with the one the app
/// runs on marked, and a way to remove each. Removing a phone makes it use the
/// password again; removing this one also turns the sign-in off here.
class FingerprintPhonesScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DeviceKeyListBloc(repository: context.read<DeviceKeyRepository>())
            ..add(const DeviceKeyListStarted()),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MultiBlocListener(
      listeners: [
        BlocListener<DeviceKeyListBloc, DeviceKeyListState>(
          listenWhen: (previous, current) =>
              previous.removedCount != current.removedCount,
          listener: (context, state) =>
              showSuccessSnackBar(context, l10n.fingerprintPhoneRemoved),
        ),
        BlocListener<DeviceKeyListBloc, DeviceKeyListState>(
          listenWhen: (previous, current) =>
              previous.failedAction != current.failedAction &&
              current.failedAction != null,
          listener: (context, state) {
            final action = state.failedAction;
            if (action == null) return;
            showFailureSnackBar(context, switch (state.failure) {
              DeviceKeyListFailure.offline => l10n.fingerprintSignInOffline,
              DeviceKeyListFailure.busy => l10n.fingerprintSignInBusy,
              _ => l10n.fingerprintSignInFailed,
            }, onRetry: () => context.read<DeviceKeyListBloc>().add(action));
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.fingerprintPhonesTitle)),
        body: const _Body(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DeviceKeyListBloc>();
    final state = context.watch<DeviceKeyListBloc>().state;
    final l10n = context.l10n;

    return switch (state.status) {
      DeviceKeyListStatus.loading => const _Skeleton(),
      DeviceKeyListStatus.noConnection => FailureView(
        kind: FailureKind.noConnection,
        onRetry: () => bloc.add(const DeviceKeyListRetried()),
      ),
      DeviceKeyListStatus.failure => FailureView(
        kind: FailureKind.error,
        onRetry: () => bloc.add(const DeviceKeyListRetried()),
      ),
      DeviceKeyListStatus.ready when state.keys.isEmpty => StateView(
        icon: LucideIcons.fingerprintPattern,
        title: l10n.fingerprintPhonesEmptyTitle,
        message: l10n.fingerprintPhonesEmptyMessage,
        actionLabel: l10n.fingerprintPhonesEmptyAction,
        onAction: () => context.popOrGo(AppRoutes.settings),
      ),
      DeviceKeyListStatus.ready => _List(state: state),
    };
  }
}

class _List extends StatelessWidget {
  const new({required this.state});

  final DeviceKeyListState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          context.l10n.fingerprintPhonesIntro,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        for (final key in state.keys) ...[
          _PhoneRow(entry: key, removing: state.removingId == key.deviceId),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// A tonal row: the kind of phone, its name, when it signed the account in
/// last and when its key expires, and the remove button.
class _PhoneRow extends StatelessWidget {
  const new({required this.entry, required this.removing});

  final DeviceKeyEntry entry;
  final bool removing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final days = context.dayFormatter;
    final today = context.read<Clock>().now();
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final lastUsedAt = entry.lastUsedAt;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 4, 12),
          child: Row(
            children: [
              IconCircle(
                icon: entry.platform == DevicePlatform.ios
                    ? LucideIcons.smartphone
                    : LucideIcons.smartphone,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.deviceName, style: theme.textTheme.bodyLarge),
                    if (entry.isCurrent)
                      Text(
                        l10n.fingerprintPhoneThisPhone,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    Text(
                      lastUsedAt == null
                          ? l10n.fingerprintPhoneNeverUsed
                          : l10n.fingerprintPhoneLastUsed(
                              date: days.formatDate(
                                lastUsedAt.toLocal(),
                                today: today,
                              ),
                            ),
                      style: secondary,
                    ),
                    Text(
                      l10n.fingerprintPhoneExpires(
                        date: days.formatDate(
                          entry.expiresAt.toLocal(),
                          today: today,
                        ),
                      ),
                      style: secondary,
                    ),
                  ],
                ),
              ),
              if (removing)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(LucideIcons.trash2),
                  tooltip: l10n.fingerprintPhoneRemoveTooltip(
                    name: entry.deviceName,
                  ),
                  onPressed: () => _remove(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _remove(BuildContext context) async {
    final bloc = context.read<DeviceKeyListBloc>();
    final confirmed = await confirmRemovePhone(
      context,
      name: entry.deviceName,
      isThisPhone: entry.isCurrent,
    );
    if (confirmed) bloc.add(DeviceKeyRemoved(entry.deviceId));
  }
}

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
