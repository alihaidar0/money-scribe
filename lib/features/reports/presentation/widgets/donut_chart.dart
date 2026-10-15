import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The ring of the spending by category. Each value is a slice, in the order
/// given, with a small gap between slices. In a right-to-left language the
/// slices run the other way round, like the rest of the layout. The [center]
/// is drawn in the hole.
class DonutChart extends StatelessWidget {
  const new({
    required this.values,
    required this.colors,
    required this.center,
    this.semanticLabel,
    super.key,
  });

  /// The widest the ring grows.
  static const maxDiameter = 240.0;

  static const _strokeWidth = 28.0;

  /// The values of the slices (the amounts in minor units). Zero or negative
  /// values have no slice.
  final List<int> values;

  /// The colour of each slice; a shorter list is used again from its start.
  final List<Color> colors;
  final Widget center;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);

    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final diameter = math.min(constraints.maxWidth, maxDiameter);

          return SizedBox.square(
            dimension: diameter,
            child: CustomPaint(
              painter: _DonutPainter(
                values: values,
                colors: colors,
                trackColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                reversed: textDirection == TextDirection.rtl,
              ),
              child: Center(
                child: Padding(
                  // Inside the ring, with a little air.
                  padding: const EdgeInsets.all(_strokeWidth + 12),
                  child: FittedBox(fit: BoxFit.scaleDown, child: center),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const new({
    required this.values,
    required this.colors,
    required this.trackColor,
    required this.reversed,
  });

  /// The gap between two slices, in radians.
  static const _gap = 0.04;

  final List<int> values;
  final List<Color> colors;
  final Color trackColor;
  final bool reversed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(DonutChart._strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = DonutChart._strokeWidth;

    // The track shows when there is nothing to draw.
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = trackColor);

    final total = values.where((value) => value > 0).fold<int>(0, _sum);
    if (total == 0) return;

    final direction = reversed ? -1.0 : 1.0;
    final slices = values.where((value) => value > 0).length;
    // One slice fills the ring without a gap.
    final gap = slices > 1 ? _gap : 0.0;
    var start = -math.pi / 2;
    var index = 0;
    for (final value in values) {
      if (value <= 0) continue;
      final sweep = value / total * math.pi * 2;
      canvas.drawArc(
        rect,
        start + direction * gap / 2,
        direction * math.max(sweep - gap, 0.001),
        false,
        paint..color = colors[index % colors.length],
      );
      start += direction * sweep;
      index++;
    }
  }

  static int _sum(int sum, int value) => sum + value;

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.colors != colors ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.reversed != reversed;
  }
}
