import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/presentation/email_change_outcome.dart';
import 'package:money_scribe/features/auth/presentation/widgets/code_entry_page.dart';
import 'package:money_scribe/features/auth/presentation/widgets/password_prompt_dialog.dart';

/// ST-12b: type the code sent to the new address. A correct code gives the
/// account its new address. A new code asks for the password again. The
/// screen answers how the change ended ([EmailChangeOutcome]).
class ChangeEmailCodeScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return CodeEntryPage(
      purpose: CodePurpose.changeEmail,
      title: l10n.changeEmailCodeTitle,
      actionLabel: l10n.verifyAction,
      askPassword: (context) => showPasswordPrompt(
        context,
        title: l10n.resendPasswordTitle,
        message: l10n.resendPasswordMessage,
        actionLabel: l10n.sendCode,
      ),
      backLabel: l10n.useAnotherAddress,
      cancelLabel: l10n.cancelEmailChange,
      onCancel: _cancel,
      onVerified: (context) => context.pop(EmailChangeOutcome.changed),
    );
  }

  /// Drops the pending change on the server, then leaves the flow. A failure
  /// is told and the person stays: the code would still work.
  Future<void> _cancel(BuildContext context) async {
    final repository = context.read<AuthRepository>();
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await repository.cancelEmailChange();
    } on DataException {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.cancelEmailChangeFailed)));
      return;
    }
    router.pop(EmailChangeOutcome.cancelled);
  }
}
