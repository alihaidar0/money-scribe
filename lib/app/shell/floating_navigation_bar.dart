import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One destination of the [FloatingNavigationBar] or of the navigation rail.
class NavigationItem {
  const new({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;

  /// The icon while the destination is the selected one (a heavier stroke).
  final IconData selectedIcon;
  final String label;
}

/// The navigation bar of phones: a rounded bar that floats above the screen.
/// The selected destination grows into a pill with its icon and its label and
/// the others show their icon only, so no label ever wraps onto a second line,
/// however long it is.
///
/// Every destination has a semantic label and a tooltip, so the icon-only ones
/// are still announced and can be read by a long press.
class FloatingNavigationBar extends StatelessWidget {
  const new({
    required this.selectedIndex,
    required this.items,
    required this.onSelected,
    super.key,
  });

  /// The widest the bar gets, so it stays a bar on a large phone or a folded
  /// tablet.
  static const maxWidth = 400.0;

  static const _height = 64.0;
  static const _padding = 6.0;
  static const double _tabHeight = _height - 2 * _padding;

  /// The width of a destination that is not selected: the touch target.
  static const _collapsedWidth = 48.0;

  static const _animation = Duration(milliseconds: 250);

  final int selectedIndex;
  final List<NavigationItem> items;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxWidth),
            child: Material(
              color: scheme.surfaceContainerHigh,
              elevation: 3,
              shadowColor: scheme.shadow,
              shape: const StadiumBorder(),
              child: Padding(
                padding: const EdgeInsets.all(_padding),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // The selected destination takes what the others leave.
                    final selectedWidth = math.max(
                      _collapsedWidth,
                      constraints.maxWidth -
                          (items.length - 1) * _collapsedWidth,
                    );
                    return Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          _Tab(
                            item: items[i],
                            selected: i == selectedIndex,
                            width: i == selectedIndex
                                ? selectedWidth
                                : _collapsedWidth,
                            onTap: () => onSelected(i),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const new({
    required this.item,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final NavigationItem item;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = selected
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        excludeFromSemantics: true,
        preferBelow: false,
        child: AnimatedContainer(
          duration: FloatingNavigationBar._animation,
          curve: Curves.easeOutCubic,
          width: width,
          height: FloatingNavigationBar._tabHeight,
          decoration: ShapeDecoration(
            color: selected ? scheme.secondaryContainer : Colors.transparent,
            shape: const StadiumBorder(),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onTap,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? item.selectedIcon : item.icon,
                        color: color,
                      ),
                      if (selected)
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(start: 8),
                            // Shrinks the label before it could wrap or
                            // overflow, with a long word or large text.
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                item.label,
                                maxLines: 1,
                                softWrap: false,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
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
