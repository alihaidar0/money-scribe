import 'package:flutter/material.dart';
import 'package:money_scribe/core/formatting/decimal_input_formatter.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/widgets/app_text_field.dart';

/// A field for an amount of money. While it is being edited it holds the plain
/// number, such as `100000.50`, which only accepts what [Money.tryParse]
/// reads. When it loses focus the number is shown grouped and with every
/// decimal, such as `100,000.50`, and it goes back to plain when it is
/// edited again. Read the value with [Money.tryParse] on the controller's text
/// while it is focused, or let the form keep its own copy through [onChanged].
class AmountField extends StatefulWidget {
  const new({
    required this.controller,
    required this.label,
    required this.currency,
    this.errorText,
    this.hintText,
    this.alwaysFloatLabel = false,
    this.textInputAction,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final Currency currency;
  final String? errorText;
  final String? hintText;
  final bool alwaysFloatLabel;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  final _focusNode = FocusNode();
  var _formatted = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Show the number the form starts with in its grouped form.
    if (!_focusNode.hasFocus && !_formatted) _group();
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _ungroup();
    } else {
      _group();
    }
  }

  void _group() {
    final money = Money.tryParse(widget.controller.text, widget.currency);
    if (money == null) return;
    widget.controller.text = context.moneyFormatter.formatAmount(money);
    _formatted = true;
  }

  void _ungroup() {
    if (!_formatted) return;
    _formatted = false;
    final plain = widget.controller.text.replaceAll(',', '');
    widget.controller.value = TextEditingValue(
      text: plain,
      selection: TextSelection.collapsed(offset: plain.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      focusNode: _focusNode,
      label: widget.label,
      unit: widget.currency.displaySymbol,
      errorText: widget.errorText,
      hintText: widget.hintText,
      alwaysFloatLabel: widget.alwaysFloatLabel,
      // Left to right in every language, so the symbol stays after the number.
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.end,
      textInputAction: widget.textInputAction,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        DecimalInputFormatter(
          maxFractionDigits: widget.currency.fractionDigits,
        ),
      ],
      onChanged: widget.onChanged,
    );
  }
}
