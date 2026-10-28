import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';
import 'package:money_scribe/features/transactions/presentation/account_icons.dart';

/// What the person chose in the account sheet.
sealed class AccountSheetResult {
  const new();
}

/// An account was chosen.
final class AccountChosen extends AccountSheetResult {
  const new(this.account);

  final Account account;
}

/// "Add account" was pressed.
final class AddAccountRequested extends AccountSheetResult {
  const new();
}

/// "Manage accounts" was pressed.
final class ManageAccountsRequested extends AccountSheetResult {
  const new();
}

/// TX-6: the bottom sheet that chooses the account of a transaction, with a
/// way to add an account and to manage them. Closes with what was done, or
/// with `null` when dismissed.
Future<AccountSheetResult?> showAccountSheet(
  BuildContext context, {
  required List<Account> accounts,
  required String? selectedId,
}) {
  return showModalBottomSheet<AccountSheetResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Over the navigation bar too, which stays dimmed and inactive.
    useRootNavigator: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                sheetContext.l10n.accountLabel,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            for (final account in accounts)
              Semantics(
                inMutuallyExclusiveGroup: true,
                checked: account.id == selectedId,
                child: ListTile(
                  leading: Icon(accountIcon(account.kind)),
                  title: Text(account.name),
                  trailing: Icon(
                    account.id == selectedId
                        ? LucideIcons.circleDot
                        : LucideIcons.circle,
                  ),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(AccountChosen(account)),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(sheetContext)
                          .pop(const AddAccountRequested()),
                  child: Text(sheetContext.l10n.addAccountAction),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(sheetContext)
                          .pop(const ManageAccountsRequested()),
                  child: Text(sheetContext.l10n.manageAccountsAction),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
