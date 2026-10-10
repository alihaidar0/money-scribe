import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/theme/app_theme.dart';
import 'package:money_scribe/app/theme/money_colors.dart';

import 'design_file_parser.dart';

List<Color> _flatten(MoneyColor color) => [
  color.color,
  color.onColor,
  color.container,
  color.onContainer,
];

void main() {
  final rows = designColorRows(8);

  test('every money token of DESIGN.md is in the extension', () {
    expect(rows.keys, {'income', 'expense', 'borrowed', 'lent', 'overdue'});
  });

  group('the colours match DESIGN.md', () {
    final tokens = {
      'income': (MoneyColors m) => m.income,
      'expense': (MoneyColors m) => m.expense,
      'borrowed': (MoneyColors m) => m.borrowed,
      'lent': (MoneyColors m) => m.lent,
      'overdue': (MoneyColors m) => m.overdue,
    };

    for (final MapEntry(key: name, value: pick) in tokens.entries) {
      test(name, () {
        final expected = rows[name]!.map((c) => c.toARGB32()).toList();

        expect(
          [
            ..._flatten(pick(MoneyColors.light)),
            ..._flatten(pick(MoneyColors.dark)),
          ].map((c) => c.toARGB32()),
          expected,
        );
      });
    }
  });

  group('lerp', () {
    test('returns the start at 0 and the end at 1', () {
      expect(MoneyColors.light.lerp(MoneyColors.dark, 0), MoneyColors.light);
      expect(MoneyColors.light.lerp(MoneyColors.dark, 1), MoneyColors.dark);
    });

    test('blends the colours in between', () {
      final middle = MoneyColors.light.lerp(MoneyColors.dark, 0.5);

      expect(
        middle.income.color,
        Color.lerp(
          MoneyColors.light.income.color,
          MoneyColors.dark.income.color,
          0.5,
        ),
      );
    });

    test('keeps the colours when there is nothing to blend with', () {
      expect(MoneyColors.light.lerp(null, 0.5), MoneyColors.light);
    });
  });

  test('copyWith replaces only the given token', () {
    final changed = MoneyColors.light.copyWith(income: MoneyColors.dark.income);

    expect(changed.income, MoneyColors.dark.income);
    expect(changed.expense, MoneyColors.light.expense);
  });

  for (final (name, theme, expected) in [
    ('light', AppTheme.light, MoneyColors.light),
    ('dark', AppTheme.dark, MoneyColors.dark),
  ]) {
    testWidgets('the $name theme exposes its money colours', (tester) async {
      late MoneyColors found;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              found = context.moneyColors;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(found.income, expected.income);
      expect(found.overdue, expected.overdue);
    });
  }
}
