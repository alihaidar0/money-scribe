import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A word or phrase inside a sentence that looks like a link. Without
/// [onTap] it is styled as a link but does nothing yet.
class TextLink {
  const new(this.label, {this.onTap});

  final String label;
  final VoidCallback? onTap;
}

/// A sentence with links inside it. The wording comes from a translated
/// message with placeholders for the links, so every language can put them
/// where its grammar wants: [message] receives one marker per link, to be
/// passed as the placeholders, and the markers are swapped for the links.
class LinkedText extends StatefulWidget {
  const new({
    required this.message,
    required this.links,
    this.style,
    this.textAlign,
    super.key,
  });

  final String Function(List<String> placeholders) message;
  final List<TextLink> links;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  State<LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<LinkedText> {
  // Private-use characters, which no translation contains.
  static final _open = String.fromCharCode(0xE000);
  static final _close = String.fromCharCode(0xE001);
  static final _marker = RegExp('$_open(\\d+)$_close');

  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final theme = Theme.of(context);
    final style = widget.style ?? theme.textTheme.bodyMedium;
    final linkStyle = style?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
    );

    final text = widget.message([
      for (var index = 0; index < widget.links.length; index++)
        '$_open$index$_close',
    ]);

    final spans = <InlineSpan>[];
    var position = 0;
    for (final match in _marker.allMatches(text)) {
      if (match.start > position) {
        spans.add(TextSpan(text: text.substring(position, match.start)));
      }
      final link = widget.links[int.parse(match.group(1)!)];
      TapGestureRecognizer? recognizer;
      if (link.onTap != null) {
        recognizer = TapGestureRecognizer()..onTap = link.onTap;
        _recognizers.add(recognizer);
      }
      spans.add(
        TextSpan(text: link.label, style: linkStyle, recognizer: recognizer),
      );
      position = match.end;
    }
    if (position < text.length) {
      spans.add(TextSpan(text: text.substring(position)));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: style,
      textAlign: widget.textAlign,
    );
  }
}
