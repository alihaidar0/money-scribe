import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';

/// FIX-5: asks whether to delete the fixed item called [name]. Answers `true`
/// for Delete, `false` for Cancel or a tap outside. Delete is in the error
/// colours.
Future<bool> confirmDeleteFixedItem(
  BuildContext context, {
  required String name,
}) async {
  final l10n = context.l10n;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colors = Theme.of(dialogContext).colorScheme;

      return AlertDialog(
        title: Text(l10n.deleteFixedItemTitle),
        content: Text(l10n.deleteFixedItemMessage(name: name)),
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
            child: Text(l10n.deleteAction),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
