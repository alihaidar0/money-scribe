import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An outlined text field (radius 12, from the theme) with the options the
/// forms of the app need.
class AppTextField extends StatelessWidget {
  const new({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.textDirection,
    this.enabled = true,
    this.obscureText = false,
    this.helperText,
    this.errorText,
    this.error,
    this.showErrorOutline = false,
    this.suffixIcon,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  /// Forces the direction of the typed text, for example left to right for an
  /// email address inside a right-to-left screen.
  final TextDirection? textDirection;

  final bool enabled;
  final bool obscureText;
  final String? helperText;

  /// An error sentence under the field.
  final String? errorText;

  /// An error that is more than text, such as a sentence with a link. Used
  /// instead of [errorText].
  final Widget? error;

  /// Draws the error outline without any text, when a banner above the form
  /// already says what is wrong.
  final bool showErrorOutline;

  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final outlineOnly = showErrorOutline && errorText == null && error == null;

    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      textDirection: textDirection,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autocorrect: !obscureText && keyboardType != TextInputType.emailAddress,
      enableSuggestions: !obscureText,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperMaxLines: 2,
        errorText: outlineOnly ? ' ' : errorText,
        // A blank error line would still take room: collapse it.
        errorStyle: outlineOnly
            ? const TextStyle(fontSize: 0, height: 0)
            : null,
        error: error,
        errorMaxLines: 3,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
