import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/password_field.dart';

/// Asks the person to type their current password again before something
/// sensitive, and answers it exactly as typed, or `null` when they cancel.
/// The password is only returned: nothing is kept here.
Future<String?> showPasswordPrompt(
  BuildContext context, {
  required String title,
  required String message,
  required String actionLabel,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PasswordPrompt(
      title: title,
      message: message,
      actionLabel: actionLabel,
    ),
  );
}

class _PasswordPrompt extends StatefulWidget {
  const new({
    required this.title,
    required this.message,
    required this.actionLabel,
  });

  final String title;
  final String message;
  final String actionLabel;

  @override
  State<_PasswordPrompt> createState() => _PasswordPromptState();
}

class _PasswordPromptState extends State<_PasswordPrompt> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_password.text.isNotEmpty) Navigator.of(context).pop(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.message),
            const SizedBox(height: 16),
            PasswordField(
              controller: _password,
              label: l10n.passwordLabel,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _confirm(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelAction),
        ),
        FilledButton(
          onPressed: _password.text.isEmpty ? null : _confirm,
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
