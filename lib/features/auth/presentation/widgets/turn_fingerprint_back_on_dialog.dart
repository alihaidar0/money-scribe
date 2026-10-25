import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';

/// Asks whether to turn the fingerprint sign-in on again after the password
/// was changed, which made the server remove its key. Answers `true` for Turn
/// on, `false` for Not now or a tap outside.
Future<bool> confirmTurnFingerprintBackOn(BuildContext context) async {
  final l10n = context.l10n;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.fingerprintBackOnTitle),
      content: Text(l10n.fingerprintBackOnMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.notNowAction),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.fingerprintBackOnAction),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
