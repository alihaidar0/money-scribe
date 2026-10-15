import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';

/// A grey block standing in for content that is loading. It does not move, so
/// it respects reduced motion and tests can settle.
class SkeletonBox extends StatelessWidget {
  const new({this.height = 64, this.width, this.radius = 16, super.key});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Wraps a screen's skeleton so a screen reader says it is loading.
class SkeletonScope extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.loadingLabel,
      liveRegion: true,
      child: child,
    );
  }
}
