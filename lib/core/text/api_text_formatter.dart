import 'package:flutter/services.dart';
import 'package:money_scribe/core/text/api_text.dart';

/// Removes what the server refuses from a text field while the person types
/// and when they paste (see [ApiText]). The cursor and the selection keep
/// their place in the text that is left.
///
/// A single-line field drops a pasted line break before this runs (Flutter's
/// own formatter comes first), so the break is removed there and not turned
/// into a space; [ApiText.clean] does the latter for any text that reaches it.
class ApiTextFormatter extends TextInputFormatter {
  const new();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final cleaned = ApiText.clean(text);
    if (cleaned == text) return newValue;

    int shifted(int offset) =>
        offset < 0 ? offset : ApiText.clean(text.substring(0, offset)).length;

    final selection = newValue.selection;
    final composing = newValue.composing;
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection(
        baseOffset: shifted(selection.baseOffset),
        extentOffset: shifted(selection.extentOffset),
        affinity: selection.affinity,
        isDirectional: selection.isDirectional,
      ),
      composing: composing.isValid && !composing.isCollapsed
          ? TextRange(
              start: shifted(composing.start),
              end: shifted(composing.end),
            )
          : TextRange.empty,
    );
  }
}
