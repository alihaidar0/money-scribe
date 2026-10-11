import 'package:flutter/material.dart';

/// Four round dots that fill as the digits of a PIN are typed. Turns to the
/// error colour when [hasError] is set.
class PinDots extends StatelessWidget {
  const new({
    required this.filled,
    this.length = 4,
    this.hasError = false,
    super.key,
  });

  final int filled;
  final int length;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = hasError ? colors.error : colors.primary;

    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < length; index++)
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < filled ? color : Colors.transparent,
                border: Border.all(color: color, width: 2),
              ),
            ),
        ],
      ),
    );
  }
}

/// A numeric pad of twelve round keys in a 3 x 4 grid: 1-9, an empty place,
/// 0 and backspace. Digits are always Western and the grid keeps its order in
/// every language.
class PinPad extends StatelessWidget {
  const new({
    required this.onDigit,
    required this.onBackspace,
    required this.backspaceLabel,
    this.enabled = true,
    super.key,
  });

  static const _keySize = 72.0;

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;

  /// What a screen reader says for the backspace key.
  final String backspaceLabel;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in const [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
          ])
            _row([for (final digit in row) _digit(context, digit)]),
          _row([
            const SizedBox(width: _keySize, height: _keySize),
            _digit(context, 0),
            _Key(
              onPressed: enabled ? onBackspace : null,
              semanticLabel: backspaceLabel,
              child: const Icon(Icons.backspace_outlined),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _digit(BuildContext context, int digit) {
    return _Key(
      onPressed: enabled ? () => onDigit(digit) : null,
      child: Text('$digit', style: Theme.of(context).textTheme.headlineMedium),
    );
  }

  Widget _row(List<Widget> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final key in keys)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: key,
            ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const new({required this.onPressed, required this.child, this.semanticLabel});

  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: onPressed != null,
      child: Material(
        color: colors.surfaceContainerHigh,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: PinPad._keySize,
            height: PinPad._keySize,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
