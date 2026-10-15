import 'package:flutter/material.dart';
import 'package:money_scribe/core/theme/money_colors.dart';

/// How long a success message stays on screen.
const successSnackBarDuration = Duration(seconds: 2);

/// Shows [message] in a green snack bar for two seconds, with a check icon and
/// no action: it only says that what the person did worked. The green is the
/// soft income container of the theme, so it follows light and dark mode, and
/// the check keeps the meaning when the colour is not seen. It replaces any
/// snack bar that is showing.
void showSuccessSnackBar(BuildContext context, String message) {
  final green = context.moneyColors.income;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: green.container,
        duration: successSnackBarDuration,
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: green.onContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: green.onContainer)),
            ),
          ],
        ),
      ),
    );
}
