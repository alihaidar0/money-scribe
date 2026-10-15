import 'package:flutter/material.dart';
import 'package:money_scribe/core/widgets/button_spinner.dart';

/// The widest the button grows, so it stays a sensible size on a wide screen.
const _maxWidth = 720.0;

/// A filled button pinned at the bottom of a form, such as "Save". It shows a
/// spinner in place of the label while [isBusy], and is off without
/// [onPressed].
class PinnedButtonBar extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.isBusy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onPressed,
                  child: isBusy ? const ButtonSpinner() : Text(label),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
