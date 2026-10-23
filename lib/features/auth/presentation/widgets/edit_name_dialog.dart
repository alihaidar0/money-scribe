import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/button_spinner.dart';
import 'package:money_scribe/core/widgets/message_banner.dart';
import 'package:money_scribe/features/auth/bloc/edit_name_bloc.dart';
import 'package:money_scribe/features/auth/domain/account_profile.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

/// The longest name the server accepts (the contract says 100 characters), so
/// the field stops there instead of letting the person type what will be
/// refused. The server still has the last word.
const _maxNameLength = 100;

/// ST-2: asks for a new name and saves it. The dialog stays open while the
/// server answers and shows what went wrong. It answers the profile with the
/// new name once saved, or `null` when it was cancelled.
Future<AccountProfile?> showEditNameDialog(
  BuildContext context, {
  required String currentName,
}) {
  return showDialog<AccountProfile>(
    context: context,
    builder: (dialogContext) => BlocProvider(
      create: (_) => EditNameBloc(
        repository: context.read<AuthRepository>(),
        currentName: currentName,
      ),
      child: const _EditNameDialog(),
    ),
  );
}

class _EditNameDialog extends StatefulWidget {
  const new();

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final _name = TextEditingController(
    text: context.read<EditNameBloc>().state.name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _changed(String value) {
    context.read<EditNameBloc>().add(EditNameChanged(value));
  }

  void _save() => context.read<EditNameBloc>().add(const EditNameSubmitted());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<EditNameBloc, EditNameState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == EditNameStatus.saved,
      listener: (context, state) => Navigator.of(context).pop(state.profile),
      builder: (context, state) {
        final isBusy = state.status == EditNameStatus.saving;
        final banner = switch (state.status) {
          EditNameStatus.unavailable => l10n.editNameUnavailable,
          EditNameStatus.noConnection ||
          EditNameStatus.failure => l10n.editNameFailed,
          _ => null,
        };

        return AlertDialog(
          title: Text(l10n.editNameTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (banner != null) ...[
                  MessageBanner(icon: Icons.error_outline, text: banner),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _name,
                  autofocus: true,
                  enabled: !isBusy,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.name],
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(_maxNameLength),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.nameLabel,
                    errorText: state.status == EditNameStatus.rejected
                        ? _issueText(l10n, state.issue)
                        : null,
                  ),
                  onChanged: _changed,
                  onSubmitted: (_) {
                    if (state.canSave && !isBusy) _save();
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
              onPressed: state.canSave && !isBusy ? _save : null,
              child: isBusy ? const ButtonSpinner() : Text(l10n.saveAction),
            ),
          ],
        );
      },
    );
  }

  static String _issueText(AppLocalizations l10n, NameIssue? issue) {
    return switch (issue) {
      NameIssue.blank => l10n.nameBlankError,
      NameIssue.tooLong => l10n.nameTooLongError,
      NameIssue.invalid || null => l10n.registerNameInvalid,
    };
  }
}
