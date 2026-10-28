import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/widgets/app_icon_image.dart';
import 'package:money_scribe/core/widgets/flow_page.dart';
import 'package:money_scribe/features/auth/bloc/app_lock_bloc.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/app_lock_session.dart';

/// AUTH-11: the app is locked; the fingerprint opens it, or the PIN. It asks
/// for the fingerprint at once when the device has one. [returnTo] is where
/// the person was, and where the open app goes back to.
class AppLockScreen extends StatelessWidget {
  const new({this.returnTo, super.key});

  final String? returnTo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppLockBloc(
        repository: context.read<AppLockRepository>(),
        session: context.read<AppLockSession>(),
      ),
      child: _AppLockView(returnTo: returnTo),
    );
  }
}

class _AppLockView extends StatefulWidget {
  const new({required this.returnTo});

  final String? returnTo;

  @override
  State<_AppLockView> createState() => _AppLockViewState();
}

class _AppLockViewState extends State<_AppLockView> {
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The fingerprint dialog needs the words of the current language, which
    // are only known here.
    if (_started) return;
    _started = true;
    context.read<AppLockBloc>().add(
      AppLockStarted(reason: context.l10n.unlockReason),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocConsumer<AppLockBloc, AppLockState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == AppLockStatus.unlocked,
      listener: (context, state) =>
          context.go(AppRoutes.returnTo(widget.returnTo)),
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
            if (state.canUseBiometrics) ...[
              Align(
                child: IconButton.filledTonal(
                  iconSize: 44,
                  padding: const EdgeInsets.all(22),
                  tooltip: l10n.unlockWithFingerprint,
                  icon: const Icon(LucideIcons.fingerprintPattern),
                  onPressed: isChecking
                      ? null
                      : () => context.read<AppLockBloc>().add(
                          BiometricUnlockRequested(reason: l10n.unlockReason),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Semantics(
              liveRegion: notRecognised,
              child: Text(
                notRecognised
                    ? l10n.fingerprintNotRecognised
                    : state.canUseBiometrics
                    ? l10n.appLockedHint
                    : l10n.appLockedHintPinOnly,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: notRecognised ? theme.colorScheme.error : null,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  context.push(AppRoutes.pinEntryFor(widget.returnTo)),
              child: Text(l10n.usePin),
            ),
          ],
        );
      },
    );
  }
}
