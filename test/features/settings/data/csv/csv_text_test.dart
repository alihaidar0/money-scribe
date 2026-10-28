import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/settings/data/csv/csv_text.dart';

void main() {
  List<List<String>> parse(String text, [String separator = ',']) =>
      parseCsvText(text, separator: separator);

  test('splits rows and cells', () {
    expect(parse('a,b,c\r\n1,2,3\r\n'), [
      ['a', 'b', 'c'],
      ['1', '2', '3'],
    ]);
  });

  test('takes LF and CR line ends, and a last row with none', () {
    expect(parse('a\nb\rc'), [
      ['a'],
      ['b'],
      ['c'],
    ]);
  });

  test('keeps empty cells, at the end too', () {
    expect(parse('a,,c,\n'), [
      ['a', '', 'c', ''],
    ]);
  });

  test('keeps an empty row, so the rows keep their numbers', () {
    expect(parse('a\n\nb\n'), [
      ['a'],
      [''],
      ['b'],
    ]);
  });

  test('a quoted cell holds the separator, a line break and a quote', () {
    expect(parse('"a,b","line\r\nbreak","say ""hi"""\n'), [
      ['a,b', 'line\r\nbreak', 'say "hi"'],
    ]);
  });

  test('a JSON cell comes back as it was written', () {
    const json = '[{"date":"2026-10-20","amount":"50.00"}]';
    expect(parse('lent,"[{""date"":""2026-10-20"",""amount"":""50.00""}]"'), [
      ['lent', json],
    ]);
  });

  test('an empty quoted cell is a cell', () {
    expect(parse('""'), [
      [''],
    ]);
  });

  test('reads ; as the separator', () {
    expect(parse('a;"b;c";d', ';'), [
      ['a', 'b;c', 'd'],
    ]);
  });

  test('nothing is no rows', () => expect(parse(''), isEmpty));

  test('refuses a quote that is never closed', () {
    expect(() => parse('"open'), throwsFormatException);
  });

  test('refuses text right after a closing quote', () {
    expect(() => parse('"a"b'), throwsFormatException);
  });
}
