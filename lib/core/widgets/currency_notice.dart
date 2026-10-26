import 'package:flutter/material.dart';

/// A quiet line that says some records are in other currencies and so are not
/// in the figures above it: amounts of two currencies are never added.
class CurrencyNotice extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
