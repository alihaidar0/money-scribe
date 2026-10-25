import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';

/// Asks whether to remove the phone called [name] from those that can sign the
/// account in with a fingerprint. Removing [isThisPhone] also turns the sign-in
/// off here, which the message says. Answers `true` for Remove, `false` for
/// Cancel or a tap outside. Remove is in the error colours.
Future<bool> confirmRemovePhone(
  BuildContext context, {
  required String name,
  required bool isThisPhone,
}) async {
  final l10n = context.l10n;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colors = Theme.of(dialogContext).colorScheme;

      return AlertDialog(
        title: Text(l10n.fingerprintPhoneRemoveTitle(name: name)),
        content: Text(
          isThisPhone
              ? l10n.fingerprintPhoneRemoveThisMessage
              : l10n.fingerprintPhoneRemoveMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.fingerprintPhoneRemoveAction),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
