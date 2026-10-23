import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_scribe/core/formatting/countdown_format.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/core/widgets/flow_page.dart';
import 'package:money_scribe/core/widgets/pin_pad.dart';
import 'package:money_scribe/features/auth/bloc/pin_bloc.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/app_lock_session.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

/// The page with the PIN dots and the numeric pad, for the PIN entry screen
/// (AUTH-12) and the Create a PIN screen (AUTH-13).
class PinPage extends StatelessWidget {
  const new({
    required this.mode,
    required this.onAccepted,
    this.onSignedOut,
    super.key,
  });

  final PinMode mode;

  /// Called when the PIN opened the app, or was saved.
  final void Function(BuildContext context) onAccepted;

  /// Called after "Forgot PIN?" signed the person out.
  final void Function(BuildContext context)? onSignedOut;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PinBloc(
        mode: mode,
        appLock: context.read<AppLockRepository>(),
        auth: context.read<AuthRepository>(),
        session: context.read<AppLockSession>(),
        ticker: context.read<Ticker>(),
      )..add(const PinStarted()),
      child: _PinView(
        mode: mode,
        onAccepted: onAccepted,
        onSignedOut: onSignedOut,
      ),
    );
  }
}

class _PinView extends StatelessWidget {
  const new({
    required this.mode,
    required this.onAccepted,
    required this.onSignedOut,
  });

  final PinMode mode;
  final void Function(BuildContext context) onAccepted;
  final void Function(BuildContext context)? onSignedOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocConsumer<PinBloc, PinState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case PinStatus.accepted:
            onAccepted(context);
          case PinStatus.signedOut:
            onSignedOut?.call(context);
          case PinStatus.tooManyFailures:
            // The person is told on the screen they land on.
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(context.l10n.pinTooManyFailures)),
              );
            onSignedOut?.call(context);
          case PinStatus.entering ||
              PinStatus.checking ||
              PinStatus.wrong ||
              PinStatus.paused ||
              PinStatus.mismatch:
            break;
        }
      },
      builder: (context, state) {
        final isPaused = state.status == PinStatus.paused;
        final hasError =
            state.status == PinStatus.wrong ||
            state.status == PinStatus.mismatch ||
            isPaused;
        final title = switch (mode) {
          PinMode.unlock => l10n.enterPinTitle,
          PinMode.create =>
            state.stage == PinStage.repeat
                ? l10n.repeatPinTitle
                : l10n.createPinTitle,
        };

        return FlowPage(
          content: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
            if (mode == PinMode.create) ...[
              const SizedBox(height: 8),
              Text(
                l10n.createPinHint,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            PinDots(filled: state.pin.length, hasError: hasError),
            // The error line keeps its room, so the pad does not jump.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                // Two lines: the pause message is the longest.
                height: 40,
                child: hasError
                    ? Semantics(
                        liveRegion: true,
                        child: Text(
                          switch (state.status) {
                            PinStatus.mismatch => l10n.pinMismatch,
                            PinStatus.paused => l10n.pinPausedTryAgain(
                              time: formatCountdown(state.pauseSecondsLeft),
                            ),
                            _ => l10n.pinIncorrect,
                          },
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              child: PinPad(
                enabled: !state.isBusy,
                backspaceLabel: l10n.pinBackspace,
                onDigit: (digit) =>
                    context.read<PinBloc>().add(PinDigitPressed(digit)),
                onBackspace: () =>
                    context.read<PinBloc>().add(const PinBackspacePressed()),
              ),
            ),
            if (mode == PinMode.unlock) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    context.read<PinBloc>().add(const ForgotPinPressed()),
                child: Text(l10n.forgotPin),
              ),
            ],
          ],
        );
      },
    );
  }
}
