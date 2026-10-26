import 'package:flutter/material.dart';
import 'package:money_scribe/core/formatting/countdown_format.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/time/duration_seconds.dart';
import 'package:money_scribe/core/widgets/last_failure_scope.dart';

/// How long a failure message stays: long enough to press Retry, and to be
/// read on the next screen when the person has already moved on. A snack bar
/// with an action would otherwise stay until it is dismissed.
const failureSnackBarDuration = Duration(seconds: 8);

/// Shows [message] in the error colours with a Retry button (or [actionLabel]
/// in its place), for something the person did that the server did not accept.
/// With no [onRetry] there is no button. It replaces any snack bar that is
/// showing and goes away by itself after [failureSnackBarDuration], also when
/// the person has moved to another screen.
///
/// When the server has just asked the app to wait (`429`), the message says so
/// with the time left and there is no Retry button: a try now would fail.
void showFailureSnackBar(
  BuildContext context,
  String message, {
  required VoidCallback? onRetry,
  String? actionLabel,
}) {
  final colors = Theme.of(context).colorScheme;
  final l10n = context.l10n;
  final wait = LastFailureScope.maybeOf(context)?.wait;
  final text = wait == null
      ? message
      : '${l10n.tooManyRequestsTitle}. '
            '${l10n.tryAgainIn(time: formatCountdown(wait.ceilSeconds))}';

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: colors.errorContainer,
        duration: failureSnackBarDuration,
        persist: false,
        content: Row(
          children: [
            Icon(Icons.error_outline, color: colors.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ],
        ),
        action: onRetry == null || wait != null
            ? null
            : SnackBarAction(
                label: actionLabel ?? context.l10n.retryAction,
                textColor: colors.onErrorContainer,
                onPressed: onRetry,
              ),
      ),
    );
}
