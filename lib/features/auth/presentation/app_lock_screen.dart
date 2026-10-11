import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/widgets/app_icon_image.dart';
import 'package:money_scribe/core/widgets/flow_page.dart';
import 'package:money_scribe/features/auth/bloc/app_lock_bloc.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';

/// AUTH-11: the app is locked; the fingerprint opens it, or the PIN.
class AppLockScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AppLockBloc(repository: context.read<AppLockRepository>()),
      child: const _AppLockView(),
    );
  }
}

class _AppLockView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocConsumer<AppLockBloc, AppLockState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == AppLockStatus.unlocked,
      listener: (context, state) => context.go(AppRoutes.overview),
      builder: (context, state) {
        final isChecking = state.status == AppLockStatus.checking;
        final notRecognised = state.status == AppLockStatus.notRecognised;

        return FlowPage(
          showBackButton: false,
          centered: true,
          content: [
            const Align(child: AppIconImage(size: 72)),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(
                l10n.appLockedTitle,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Align(
              child: IconButton.filledTonal(
                iconSize: 44,
                padding: const EdgeInsets.all(22),
                tooltip: l10n.unlockWithFingerprint,
                icon: const Icon(Icons.fingerprint),
                onPressed: isChecking
                    ? null
                    : () => context.read<AppLockBloc>().add(
                        const BiometricUnlockRequested(),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: notRecognised,
              child: Text(
                notRecognised
                    ? l10n.fingerprintNotRecognised
                    : l10n.appLockedHint,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: notRecognised ? theme.colorScheme.error : null,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.push(AppRoutes.pinEntry),
              child: Text(l10n.usePin),
            ),
          ],
        );
      },
    );
  }
}
