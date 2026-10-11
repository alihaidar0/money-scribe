import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/icon_circle.dart';

/// The body of a screen that is not built yet. Each one is replaced by its
/// real screen as the screens are built (`docs/steps.md`, section 6).
class ComingSoonView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconCircle(icon: Icons.construction_outlined),
            const SizedBox(height: 24),
            Text(
              context.l10n.comingSoon,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
