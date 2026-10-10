import 'dart:io';
import 'dart:ui';

/// Reads the colour tables of `docs/DESIGN.md`, the source of truth for the
/// theme, so the tests fail when the document and the code drift apart.
///
/// Returns the rows that have exactly [valueCount] hex values, keyed by the
/// first cell, with each value as a colour.
Map<String, List<Color>> designColorRows(int valueCount) {
  final markdown = File('docs/DESIGN.md').readAsLinesSync();
  final hex = RegExp(r'^`#([0-9A-F]{6})`$');
  final rows = <String, List<Color>>{};
  for (final line in markdown) {
    if (!line.startsWith('|')) continue;
    final cells = line
        .split('|')
        .map((cell) => cell.trim())
        .where((cell) => cell.isNotEmpty)
        .toList();
    final values = cells.skip(1).map(hex.firstMatch).toList();
    if (values.length != valueCount || values.contains(null)) continue;
    rows[cells.first] = [
      for (final match in values)
        Color(0xFF000000 | int.parse(match!.group(1)!, radix: 16)),
    ];
  }
  return rows;
}
