import 'package:flutter/material.dart';

/// An icon on a soft, pale circle, as used by empty states, confirmations and
/// list rows (`docs/DESIGN.md`, section 2.1). Defaults to the primary tones.
class IconCircle extends StatelessWidget {
  const new({
    required this.icon,
    this.size = 96,
    this.background,
    this.foreground,
    super.key,
  });

  final IconData icon;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: background ?? colors.primaryContainer,
        ),
        child: Icon(
          icon,
          size: size * 0.5,
          color: foreground ?? colors.onPrimaryContainer,
        ),
      ),
    );
  }
}
