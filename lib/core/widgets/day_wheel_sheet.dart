import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money_scribe/core/l10n/l10n.dart';

/// A bottom sheet with a scroll wheel of the days [min] to [max], like the
/// time picker of a phone. Closes with the day chosen, or with `null` when
/// dismissed. [captionFor] says something about the day under the wheel while
/// it turns, such as the part of the month the day belongs to.
Future<int?> showDayWheelSheet(
  BuildContext context, {
  required String title,
  required int value,
  required int min,
  required int max,
  String Function(int day)? captionFor,
}) {
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    // As tall as it needs, for large text on a small screen.
    isScrollControlled: true,
    // Over the sheet it was opened from, and over the navigation bar.
    useRootNavigator: true,
    builder: (sheetContext) => _DayWheelSheet(
      title: title,
      value: value,
      min: min,
      max: max,
      captionFor: captionFor,
    ),
  );
}

class _DayWheelSheet extends StatefulWidget {
  const new({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.captionFor,
  });

  final String title;
  final int value;
  final int min;
  final int max;
  final String Function(int day)? captionFor;

  @override
  State<_DayWheelSheet> createState() => _DayWheelSheetState();
}

class _DayWheelSheetState extends State<_DayWheelSheet> {
  /// The height of one day on the wheel, and so of the band that marks the
  /// chosen one: at least a touch target.
  static const _itemExtent = 48.0;

  /// Days shown on the wheel at once; fewer on a short screen.
  static const _tallDays = 5;
  static const _shortDays = 3;
  static const _shortScreen = 560.0;

  late int _selected = widget.value.clamp(widget.min, widget.max);
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: _selected - widget.min);

  int get _count => widget.max - widget.min + 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Turns the wheel to [day], for a tap on a day and for a screen reader.
  void _goTo(int day) {
    if (day < widget.min || day > widget.max) return;
    _controller.animateToItem(
      day - widget.min,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final caption = widget.captionFor?.call(_selected);
    final days = MediaQuery.sizeOf(context).height < _shortScreen
        ? _shortDays
        : _tallDays;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(widget.title, style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 8),
            Semantics(
              label: widget.title,
              value: '$_selected',
              increasedValue: _selected < widget.max
                  ? '${_selected + 1}'
                  : null,
              decreasedValue: _selected > widget.min
                  ? '${_selected - 1}'
                  : null,
              onIncrease: _selected < widget.max
                  ? () => _goTo(_selected + 1)
                  : null,
              onDecrease: _selected > widget.min
                  ? () => _goTo(_selected - 1)
                  : null,
              excludeSemantics: true,
              child: SizedBox(
                height: days * _itemExtent,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // The band behind the chosen day.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const SizedBox(
                        height: _itemExtent,
                        width: double.infinity,
                      ),
                    ),
                    ListWheelScrollView(
                      controller: _controller,
                      itemExtent: _itemExtent,
                      diameterRatio: 2.2,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        unawaited(HapticFeedback.selectionClick());
                        setState(() => _selected = widget.min + index);
                      },
                      children: [
                        for (var i = 0; i < _count; i++)
                          _Day(
                            day: widget.min + i,
                            selected: widget.min + i == _selected,
                            onTap: () => _goTo(widget.min + i),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Reserved even when empty, so the buttons never jump.
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Center(
                child: caption == null
                    ? const SizedBox.shrink()
                    : Text(
                        caption,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancelAction),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: Text(l10n.doneAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const new({required this.day, required this.selected, required this.onTap});

  final int day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = selected
        ? theme.textTheme.titleLarge?.copyWith(
            color: scheme.onSecondaryContainer,
            fontWeight: FontWeight.w600,
          )
        : theme.textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant);

    return InkWell(
      onTap: onTap,
      child: Center(
        child: Text(
          '$day',
          style: style?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
