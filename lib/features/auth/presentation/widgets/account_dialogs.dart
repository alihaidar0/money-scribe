import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_scribe/core/formatting/countdown_format.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/button_spinner.dart';
import 'package:money_scribe/core/widgets/message_banner.dart';
import 'package:money_scribe/core/widgets/password_field.dart';
import 'package:money_scribe/features/auth/bloc/account_bloc.dart';

/// ST-10: asks whether to sign out. Answers `true` for Sign out, `false` for
/// Cancel or a tap outside.
Future<bool> confirmSignOut(BuildContext context) async {
  final l10n = context.l10n;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.signOutTitle),
      content: Text(l10n.signOutMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancelAction),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.signOutAction),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// ST-11: asks for the password and deletes the account. The dialog stays open
/// while the server answers, shows what went wrong, and closes itself once the
/// account is deleted. The router then leaves the account's screens.
Future<void> showDeleteAccountDialog(BuildContext context) {
  final bloc = context.read<AccountBloc>()
    ..add(const DeleteAccountDialogOpened());

  return showDialog<void>(
    context: context,
    builder: (dialogContext) =>
        BlocProvider.value(value: bloc, child: const _DeleteAccountDialog()),
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const new();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _delete() {
    context.read<AccountBloc>().add(DeleteAccountConfirmed(_password.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;

    return BlocConsumer<AccountBloc, AccountState>(
      listenWhen: (previous, current) =>
          previous.action != current.action &&
          current.action == AccountAction.deleted,
      listener: (context, state) => Navigator.of(context).pop(),
      buildWhen: (previous, current) =>
          previous.action != current.action ||
          previous.deleteWaitSecondsLeft != current.deleteWaitSecondsLeft,
      builder: (context, state) {
        final isBusy = state.isBusy;
        final isWaiting = state.action == AccountAction.deleteWaiting;

        return AlertDialog(
          title: Text(l10n.deleteMyAccountTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.deleteMyAccountMessage),
                const SizedBox(height: 16),
                if (state.action == AccountAction.deleteFailed) ...[
                  MessageBanner(
                    icon: Icons.error_outline,
                    text: l10n.deleteMyAccountFailed,
                  ),
                  const SizedBox(height: 16),
                ],
                if (state.action == AccountAction.deleteUnavailable) ...[
                  MessageBanner(
                    icon: Icons.error_outline,
                    text: l10n.deleteMyAccountUnavailable,
                  ),
                  const SizedBox(height: 16),
                ],
                PasswordField(
                  controller: _password,
                  label: l10n.passwordLabel,
                  enabled: !isBusy,
                  errorText: state.action == AccountAction.wrongPassword
                      ? l10n.deleteMyAccountWrongPassword
                      : null,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (_password.text.isNotEmpty && !isBusy && !isWaiting) {
                      _delete();
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isBusy ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.cancelAction),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: _password.text.isEmpty || isBusy || isWaiting
                  ? null
                  : _delete,
              child: isBusy
                  ? const ButtonSpinner()
                  // The server asked to wait: the button counts down.
                  : Text(
                      isWaiting
                          ? l10n.tryAgainIn(
                              time: formatCountdown(
                                state.deleteWaitSecondsLeft,
                              ),
                            )
                          : l10n.deleteMyAccountAction,
                    ),
            ),
          ],
        );
      },
    );
  }
}
