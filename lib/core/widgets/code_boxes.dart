import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money_scribe/core/formatting/western_digits_input_formatter.dart';

/// Four large rounded boxes for a 4-digit code, filled from a numeric
/// keypad. One invisible text field takes the typing, so paste, auto-fill and
/// the delete key all work; the boxes only show its digits. The digits keep
/// their left-to-right order in every language.
class CodeBoxes extends StatelessWidget {
  const new({
    required this.controller,
    required this.focusNode,
    required this.semanticLabel,
    this.hasError = false,
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  static const length = 4;

  final TextEditingController controller;
  final FocusNode focusNode;

  /// What a screen reader says for the code field.
  final String semanticLabel;

  /// Draws the error outline on every box.
  final bool hasError;

  /// Whether digits can be typed; off, the boxes look muted.
  final bool enabled;

  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: 64,
        child: Stack(
          children: [
            ExcludeSemantics(
              child: ListenableBuilder(
                listenable: Listenable.merge([controller, focusNode]),
                builder: (context, _) => _boxes(context),
              ),
            ),
            Positioned.fill(
              child: Semantics(
                label: semanticLabel,
                textField: true,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    const WesternDigitsInputFormatter(),
                    LengthLimitingTextInputFormatter(length),
                  ],
                  showCursor: false,
                  enableInteractiveSelection: false,
                  enableSuggestions: false,
                  autocorrect: false,
                  style: const TextStyle(color: Colors.transparent),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                  ),
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boxes(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final digits = controller.text;
    final focusedIndex = focusNode.hasFocus && enabled
        ? digits.length.clamp(0, length - 1)
        : -1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < length; index++) ...[
          if (index > 0) const SizedBox(width: 12),
          _Box(
            digit: index < digits.length ? digits[index] : '',
            borderColor: hasError
                ? colors.error
                : index == focusedIndex
                ? colors.primary
                : enabled
                ? colors.outline
                : colors.onSurface.withValues(alpha: 0.12),
            borderWidth: hasError || index == focusedIndex ? 2 : 1,
            textColor: enabled
                ? colors.onSurface
                : colors.onSurface.withValues(alpha: 0.38),
          ),
        ],
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const new({
    required this.digit,
    required this.borderColor,
    required this.borderWidth,
    required this.textColor,
  });

  final String digit;
  final Color borderColor;
  final double borderWidth;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Text(
        digit,
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(color: textColor),
      ),
    );
  }
}
