import 'package:flutter/material.dart';

/// Two blocks of content that sit side by side when there is room for both and
/// one under the other when there is not: a phone shows [first] then [second],
/// a tablet or the web shows them as two columns. When one of them is empty the
/// other takes the whole width.
class TwoColumns extends StatelessWidget {
  const new({
    required this.first,
    required this.second,
    this.gap = 24,
    super.key,
  });

  /// The content width from which the blocks sit side by side.
  static const sideBySideFrom = 720.0;

  final List<Widget> first;
  final List<Widget> second;

  /// The space between the columns, and between the blocks when stacked.
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget column(List<Widget> children) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        }

        if (first.isEmpty || second.isEmpty) {
          return column([...first, ...second]);
        }

        if (constraints.maxWidth < sideBySideFrom) {
          return column([...first, SizedBox(height: gap), ...second]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: column(first)),
            SizedBox(width: gap),
            Expanded(child: column(second)),
          ],
        );
      },
    );
  }
}
