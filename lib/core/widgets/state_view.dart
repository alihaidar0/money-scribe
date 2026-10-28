import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/clipboard/text_clipboard.dart';
import 'package:money_scribe/core/formatting/countdown_format.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/time/duration_seconds.dart';
import 'package:money_scribe/core/widgets/icon_circle.dart';
import 'package:money_scribe/core/widgets/last_failure_scope.dart';

/// Why a screen cannot show its content.
enum FailureKind {
  /// The server cannot be reached.
  noConnection,

  /// The server failed.
  error,

  /// The server is busy and refused the request before changing anything:
  /// asking again shortly is safe.
  unavailable,

  /// The server does not offer this yet. Trying again does not help: the only
  /// way out is back.
  notAvailable,
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
    this.secondaryLabel,
    this.onSecondary,
    this.footer,
    super.key,
  });

  final IconData icon;
  final String title;

  /// A second, quieter action under the first, such as "Copy from last
  /// month" under "Add item". Shown when [secondaryLabel] is set; with no
  /// [onSecondary] it is disabled.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// The sentence under the title, when the title does not say enough.
  final String? message;

  /// Quiet content under the buttons, such as the reference of a failed
  /// request.
  final Widget? footer;

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
              if (secondaryLabel != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onSecondary,
                  child: Text(secondaryLabel!),
                ),
              ],
              if (footer != null) ...[const SizedBox(height: 16), footer!],
            ],
          ),
        ),
      ),
    );
  }
}

/// The full-screen state for a failure: "No connection", "Something went
/// wrong" or "The service is busy", each with a "Try again" button, or "Not
/// available yet", with a "Go back" button.
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
    final failure = LastFailureScope.maybeOf(context);

    // The server asked the app to slow down: whatever the screen reports, the
    // button counts down the wait instead of inviting a try that would fail.
    final wait = failure?.wait;
    if (wait != null &&
        (kind == FailureKind.error || kind == FailureKind.unavailable)) {
      return _WaitView(wait: wait, onRetry: onRetry);
    }

    // The reference helps support find a request that failed on the server.
    final reference =
        kind == FailureKind.error || kind == FailureKind.unavailable
        ? failure?.requestId
        : null;
    final footer = reference == null ? null : _ReferenceLine(reference);

    return switch (kind) {
      FailureKind.noConnection => StateView(
        icon: LucideIcons.cloudOff,
        title: l10n.noConnectionTitle,
        message: l10n.noConnectionMessage,
        actionLabel: l10n.tryAgain,
        onAction: onRetry,
      ),
      FailureKind.error => StateView(
        icon: LucideIcons.circleAlert,
        title: errorTitle ?? l10n.errorTitle,
        message: errorTitle == null ? l10n.errorMessage : null,
        actionLabel: l10n.tryAgain,
        onAction: onRetry,
        footer: footer,
      ),
      FailureKind.unavailable => StateView(
        icon: LucideIcons.hourglass,
        title: l10n.unavailableTitle,
        message: l10n.unavailableMessage,
        actionLabel: l10n.tryAgain,
        onAction: onRetry,
        footer: footer,
      ),
      FailureKind.notAvailable => StateView(
        icon: LucideIcons.construction,
        title: l10n.notAvailableTitle,
        message: l10n.notAvailableMessage,
        actionLabel: l10n.goBackAction,
        onAction: () => Navigator.of(context).maybePop(),
      ),
    };
  }
}

/// "Reference: 7c1f0d52-..." with a button that copies the code.
class _ReferenceLine extends StatelessWidget {
  const new(this.reference);

  final String reference;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SelectableText(
            // The code is Latin letters, digits and hyphens: isolated so it
            // reads left to right inside Arabic text.
            l10n.requestReference(reference: '\u2066$reference\u2069'),
            style: style,
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          icon: const Icon(LucideIcons.copy, size: 18),
          tooltip: l10n.copyReferenceTooltip,
          onPressed: () async {
            final messenger = ScaffoldMessenger.maybeOf(context);
            final message = l10n.referenceCopied;
            await context.read<TextClipboard>().copy(reference);
            messenger?.showSnackBar(SnackBar(content: Text(message)));
          },
        ),
      ],
    );
  }
}

/// "Too many requests" with a Try again button that stays disabled and counts
/// down until the wait the server asked for is over.
class _WaitView extends StatefulWidget {
  const new({required this.wait, required this.onRetry});

  final Duration wait;
  final VoidCallback onRetry;

  @override
  State<_WaitView> createState() => _WaitViewState();
}

class _WaitViewState extends State<_WaitView> {
  late int _secondsLeft = widget.wait.ceilSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final waiting = _secondsLeft > 0;

    return StateView(
      icon: LucideIcons.hourglass,
      title: l10n.tooManyRequestsTitle,
      message: l10n.tooManyRequestsMessage,
      actionLabel: waiting
          ? l10n.tryAgainIn(time: formatCountdown(_secondsLeft))
          : l10n.tryAgain,
      onAction: waiting ? null : widget.onRetry,
    );
  }
}
