import 'package:flutter/material.dart';

/// A choice between a few options, drawn as a soft pill track with the chosen
/// option as a filled pill inside it (`docs/DESIGN.md`). It takes the same
/// [ButtonSegment]s as Flutter's `SegmentedButton`, which it replaces
/// everywhere in the app so every choice looks the same.
///
/// The options share the width equally. A label that does not fit wraps, and
/// every option is as tall as the tallest, so nothing is cut off at a large
/// text size. Without [onSelectionChanged] the options are off.
class PillSegmentedButton<T> extends StatelessWidget {
  const new({
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
    super.key,
  });

  /// The track around the options.
  static const _trackPadding = 4.0;

  /// The fewest dp an option is tall, so it can be touched.
  static const _minOptionHeight = 48.0;

  final List<ButtonSegment<T>> segments;

  /// The chosen option: a set of one, as for `SegmentedButton`.
  final Set<T> selected;
  final ValueChanged<Set<T>>? onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Padding(
          padding: const EdgeInsets.all(_trackPadding),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final segment in segments)
                  Expanded(
                    child: _Option<T>(
                      segment: segment,
                      isSelected: selected.contains(segment.value),
                      onPressed: onSelectionChanged == null || !segment.enabled
                          ? null
                          : () => onSelectionChanged!({segment.value}),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Option<T> extends StatelessWidget {
  const new({
    required this.segment,
    required this.isSelected,
    required this.onPressed,
  });

  final ButtonSegment<T> segment;
  final bool isSelected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = onPressed != null;
    final color = isSelected
        ? colors.onPrimary
        : enabled
        ? colors.onSurfaceVariant
        : colors.onSurface.withValues(alpha: 0.38);

    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      enabled: enabled,
      child: Material(
        color: isSelected ? colors.primary : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: PillSegmentedButton._minOptionHeight,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: DefaultTextStyle.merge(
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  child: IconTheme.merge(
                    data: IconThemeData(color: color, size: 18),
                    child: segment.label ?? segment.icon ?? const SizedBox(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
