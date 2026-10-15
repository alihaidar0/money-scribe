import 'package:flutter/material.dart';

/// A small tab on the end edge of the screen that opens the demo panel. Only
/// staging builds show it. It is deleted together with the fake data.
class DemoHandle extends StatelessWidget {
  const new({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PositionedDirectional(
      end: 0,
      top: MediaQuery.sizeOf(context).height * 0.4,
      child: Semantics(
        button: true,
        label: 'Demo panel',
        child: Material(
          color: colors.inverseSurface.withValues(alpha: 0.55),
          borderRadius: const BorderRadiusDirectional.horizontal(
            start: Radius.circular(12),
          ),
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: 28,
              height: 56,
              child: Icon(Icons.tune, size: 18, color: colors.onInverseSurface),
            ),
          ),
        ),
      ),
    );
  }
}
