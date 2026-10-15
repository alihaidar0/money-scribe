import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';

/// Asks whether to delete something: a dialog with a [title] and a [message]
/// that says what is lost. Answers `true` for Delete, `false` for Cancel or a
/// tap outside. Delete is in the error colours.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final l10n = context.l10n;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colors = Theme.of(dialogContext).colorScheme;

      return AlertDialog(
        title: Text(title),
        content: Text(message),
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

/// Asks whether to leave a form that has unsaved changes. Answers `true` for
/// Discard, `false` for Keep editing or a tap outside.
Future<bool> confirmDiscard(BuildContext context) async {
  final l10n = context.l10n;

  final discard = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.discardChangesTitle),
      content: Text(l10n.discardChangesGenericMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.keepEditingAction),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.discardAction),
        ),
      ],
    ),
  );
  return discard ?? false;
}
