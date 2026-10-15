import 'package:flutter/material.dart';

/// A small spinner to put in a button's place of the label while its action
/// is being sent.
class ButtonSpinner extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
