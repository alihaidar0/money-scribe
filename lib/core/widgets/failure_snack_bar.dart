import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';

/// Shows [message] in the error colours with a Retry button, for something the
/// person did that the server did not accept. It replaces any snack bar that
/// is showing.
void showFailureSnackBar(
  BuildContext context,
  String message, {
  required VoidCallback onRetry,
}) {
  final colors = Theme.of(context).colorScheme;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: colors.errorContainer,
        content: Row(
          children: [
            Icon(Icons.error_outline, color: colors.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: context.l10n.retryAction,
          textColor: colors.onErrorContainer,
          onPressed: onRetry,
        ),
      ),
    );
}
