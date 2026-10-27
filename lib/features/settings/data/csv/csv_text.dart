/// Reads CSV text into its rows of cells, the way RFC 4180 writes them: cells
/// split by [separator] (`,` or `;`), a cell in `"` may hold the separator, a
/// line break and `""` for a quote, and a row ends with CRLF, LF or CR.
///
/// Every row a spreadsheet shows is a row here, an empty one too, so the
/// number of a row is its index plus one. A line end after the last row adds
/// no row. Throws a [FormatException] for a quote that is never closed or text
/// right after a closing quote.
List<List<String>> parseCsvText(String text, {required String separator}) {
  assert(separator.length == 1, 'one character');
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  var afterQuote = false;
  var i = 0;

  void endCell() {
    row.add(cell.toString());
    cell.clear();
    afterQuote = false;
  }

  void endRow() {
    endCell();
    rows.add(row);
    row = <String>[];
  }

  while (i < text.length) {
    final char = text[i];
    if (quoted) {
      if (char == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i += 2;
          continue;
        }
        quoted = false;
        afterQuote = true;
      } else {
        cell.write(char);
      }
      i++;
      continue;
    }
    if (char == separator) {
      endCell();
    } else if (char == '\r' || char == '\n') {
      endRow();
      if (char == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
    } else if (afterQuote) {
      throw FormatException('Text after a closing quote', text, i);
    } else if (char == '"' && cell.isEmpty) {
      quoted = true;
    } else {
      cell.write(char);
    }
    i++;
  }
  if (quoted) throw FormatException('A quote is never closed', text, i);
  // The last row, unless the text ended with its line end.
  if (cell.isNotEmpty || row.isNotEmpty || afterQuote) endRow();
  return rows;
}
