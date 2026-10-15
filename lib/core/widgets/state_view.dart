import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/icon_circle.dart';

/// Why a screen cannot show its content.
enum FailureKind {
  /// The server cannot be reached.
  noConnection,

  /// The server failed.
  error,
}

/// A centred icon, title, sentence and one button: the pattern of every
/// empty, error and "no connection" state (`docs/DESIGN.md`, section 6).
class StateView extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.message,
    this.filledAction = false,
    super.key,
  });

  final IconData icon;
  final String title;

  /// The sentence under the title, when the title does not say enough.
  final String? message;

  /// Shows the action as a filled primary button instead of a tonal one, for
  /// an empty state that leads to the next thing to do.
  final bool filledAction;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconCircle(icon: icon),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              if (filledAction)
                FilledButton(onPressed: onAction, child: Text(actionLabel))
              else
                FilledButton.tonal(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The full-screen state for a failure: "No connection" or "Something went
/// wrong", each with a "Try again" button.
class FailureView extends StatelessWidget {
  const new({
    required this.kind,
    required this.onRetry,
    this.errorTitle,
    super.key,
  });

  final FailureKind kind;
  final VoidCallback onRetry;

  /// A title that says what could not be done, for a screen whose design has
  /// its own words for [FailureKind.error]. It replaces the title and the
  /// sentence.
  final String? errorTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return switch (kind) {
      FailureKind.noConnection => StateView(
        icon: Icons.cloud_off_outlined,
        title: l10n.noConnectionTitle,
        message: l10n.noConnectionMessage,
        actionLabel: l10n.tryAgain,
        onAction: onRetry,
      ),
      FailureKind.error => StateView(
        icon: Icons.error_outline,
        title: errorTitle ?? l10n.errorTitle,
        message: errorTitle == null ? l10n.errorMessage : null,
        actionLabel: l10n.tryAgain,
        onAction: onRetry,
      ),
    };
  }
}
