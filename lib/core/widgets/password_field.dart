import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/app_text_field.dart';

/// A password field whose eye button shows or hides the typed text.
class PasswordField extends StatefulWidget {
  const new({
    required this.controller,
    required this.label,
    this.enabled = true,
    this.helperText,
    this.errorText,
    this.showErrorOutline = false,
    this.textInputAction,
    this.autofillHints = const [AutofillHints.password],
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final String? helperText;
  final String? errorText;
  final bool showErrorOutline;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      enabled: widget.enabled,
      obscureText: !_visible,
      helperText: widget.helperText,
      errorText: widget.errorText,
      showErrorOutline: widget.showErrorOutline,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      suffixIcon: IconButton(
        tooltip: _visible ? l10n.hidePassword : l10n.showPassword,
        icon: Icon(_visible ? LucideIcons.eyeOff : LucideIcons.eye),
        onPressed: widget.enabled
            ? () => setState(() => _visible = !_visible)
            : null,
      ),
    );
  }
}
