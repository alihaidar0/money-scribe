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
    required this.message,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
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
              const SizedBox(height: 8),
              Text(
                message,
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
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
  const new({required this.kind, required this.onRetry, super.key});

  final FailureKind kind;
  final VoidCallback onRetry;

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
        title: l10n.errorTitle,
        message: l10n.errorMessage,
        actionLabel: l10n.tryAgain,
        onAction: onRetry,
      ),
    };
  }
}
