import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/app_text_field.dart';
import 'package:money_scribe/core/widgets/confirm_dialogs.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';

/// What the person did in the sheet that adds or changes an account.
sealed class AccountFormResult {
  const new();
}

/// Save: the account as it was typed.
final class AccountFormSaved extends AccountFormResult {
  const new(this.draft);

  final AccountDraft draft;
}

/// Delete, after the person confirmed it.
final class AccountFormDeleted extends AccountFormResult {
  const new();
}

/// ST-5b: the bottom sheet that adds an account, or with [account] changes
/// it, which also offers Delete. Closes with what was done, or with `null`
/// when dismissed.
Future<AccountFormResult?> showAccountFormSheet(
  BuildContext context, {
  Account? account,
}) {
  return showModalBottomSheet<AccountFormResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Over the navigation bar too, which stays dimmed and inactive.
    useRootNavigator: true,
    builder: (sheetContext) => _AccountFormSheet(account: account),
  );
}

class _AccountFormSheet extends StatefulWidget {
  const new({required this.account});

  final Account? account;

  @override
  State<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<_AccountFormSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.account?.name ?? '',
  );
  late AccountKind _kind = widget.account?.kind ?? AccountKind.card;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  AccountDraft? get _draft =>
      AccountDraft.tryCreate(name: _name.text, kind: _kind);

  Future<void> _delete() async {
    final account = widget.account;
    if (account == null) return;
    final l10n = context.l10n;
    final confirmed = await confirmDelete(
      context,
      title: l10n.accountDeleteTitle,
      message: l10n.accountDeleteMessage(name: account.name),
    );
    if (confirmed && mounted) {
      Navigator.of(context).pop(const AccountFormDeleted());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final draft = _draft;
    final editing = widget.account != null;

    return SafeArea(
      child: SingleChildScrollView(
        // Above the keyboard.
        padding: EdgeInsetsDirectional.fromSTEB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                editing ? l10n.editAccountTitle : l10n.addAccountTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _name,
              label: l10n.nameLabel,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            PillSegmentedButton<AccountKind>(
              segments: [
                ButtonSegment(
                  value: AccountKind.card,
                  label: Text(l10n.accountKindCard),
                ),
                ButtonSegment(
                  value: AccountKind.cash,
                  label: Text(l10n.accountKindCash),
                ),
                ButtonSegment(
                  value: AccountKind.other,
                  label: Text(l10n.accountKindOther),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (selection) =>
                  setState(() => _kind = selection.first),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: editing
                  ? WrapAlignment.spaceBetween
                  : WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                if (editing)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: _delete,
                    child: Text(l10n.deleteAction),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancelAction),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: draft == null
                          ? null
                          : () =>
                                Navigator.of(context)
                                    .pop(AccountFormSaved(draft)),
                      child: Text(l10n.saveAction),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
