import 'package:flutter/material.dart';

/// How wide the column of a framed screen is.
enum FrameWidth {
  /// A short form or a list of settings.
  narrow(560),

  /// A form, a details page or a list.
  regular(720),

  /// A page with two columns of its own.
  wide(1040);

  new(this.value);

  /// The width in logical pixels.
  final double value;
}

/// Frames a screen that is pushed above the navigation on a wide window (a
/// tablet or the web): the whole screen, app bar included, is one centred
/// column of [width] on a tinted canvas, as a website shows a page. Below
/// [framedFrom] (a phone) it changes nothing, so the phone keeps the full-width
/// screen of a phone app.
///
/// The child sees the width of the column as the window width, so a screen that
/// adapts to its window (`MediaQuery.sizeOf`) adapts to the column.
class WideFrame extends StatelessWidget {
  const new({required this.child, this.width = FrameWidth.regular, super.key});

  /// The window width from which the frame shows: the medium window size class.
  static const framedFrom = 600.0;

  final Widget child;
  final FrameWidth width;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width < framedFrom) return child;

    final colors = Theme.of(context).colorScheme;
    final columnWidth = width.value < media.size.width
        ? width.value
        : media.size.width;

    return ColoredBox(
      color: colors.surfaceContainer,
      child: Center(
        child: SizedBox(
          width: columnWidth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              border: BorderDirectional(
                start: BorderSide(color: colors.outlineVariant),
                end: BorderSide(color: colors.outlineVariant),
              ),
            ),
            child: MediaQuery(
              data: media.copyWith(size: Size(columnWidth, media.size.height)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
