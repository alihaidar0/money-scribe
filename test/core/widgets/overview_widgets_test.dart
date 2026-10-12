import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/theme/app_theme.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/core/widgets/amount_row.dart';
import 'package:money_scribe/core/widgets/debt_badges.dart';
import 'package:money_scribe/core/widgets/hero_card.dart';
import 'package:money_scribe/core/widgets/part_selector.dart';

Widget _host(Widget child, {ThemeData? theme, Locale? locale}) {
  return MaterialApp(
    theme: theme ?? AppTheme.light,
    locale: locale ?? const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

BoxDecoration _decorationOf(WidgetTester tester, Finder inside) {
  return tester
          .widget<DecoratedBox>(
            find
                .descendant(of: inside, matching: find.byType(DecoratedBox))
                .first,
          )
          .decoration
      as BoxDecoration;
}

void main() {
  group('HeroCard with stacked details', () {
    testWidgets('shows each label above its amount, side by side', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const HeroCard(
            label: 'Total',
            amount: '104,400.00 ₽',
            stackedDetails: true,
            details: [
              HeroDetail(label: 'Part 1', amount: '43,500.00 ₽'),
              HeroDetail(label: 'Part 2', amount: '60,900.00 ₽'),
            ],
          ),
        ),
      );

      final first = tester.getTopLeft(find.text('Part 1'));
      final second = tester.getTopLeft(find.text('Part 2'));
      expect(second.dx, greaterThan(first.dx));
      expect(second.dy, first.dy);
      expect(
        tester.getTopLeft(find.text('43,500.00 ₽')).dy,
        greaterThan(first.dy),
      );
    });
  });

  group('HeroCard', () {
    const card = HeroCard(
      label: 'Balance',
      amount: '60,650.00 ₽',
      details: [HeroDetail(label: 'Income', amount: '+109,400.00 ₽')],
    );

    testWidgets('shows the label, the amount and the details', (tester) async {
      await tester.pumpWidget(_host(card));

      expect(find.text('Balance'), findsOneWidget);
      expect(find.text('60,650.00 ₽'), findsOneWidget);
      expect(
        find.textContaining('+109,400.00 ₽', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('is navy in light mode', (tester) async {
      await tester.pumpWidget(_host(card));

      expect(
        _decorationOf(tester, find.byType(HeroCard)).color,
        AppTheme.light.colorScheme.primary,
      );
    });

    testWidgets('is the primary container in dark mode', (tester) async {
      await tester.pumpWidget(_host(card, theme: AppTheme.dark));

      expect(
        _decorationOf(tester, find.byType(HeroCard)).color,
        AppTheme.dark.colorScheme.primaryContainer,
      );
    });

    testWidgets('has no gradient', (tester) async {
      await tester.pumpWidget(_host(card));

      expect(_decorationOf(tester, find.byType(HeroCard)).gradient, isNull);
    });

    testWidgets('amounts use fixed-width figures', (tester) async {
      await tester.pumpWidget(_host(card));

      final style = tester.widget<Text>(find.text('60,650.00 ₽')).style!;

      expect(style.fontFeatures, isNotEmpty);
    });
  });

  group('AmountRow', () {
    Widget row(Money amount, {VoidCallback? onTap}) {
      return AmountRow(
        icon: Icons.payments_outlined,
        title: 'Salary',
        subtitle: '20 days',
        amount: amount,
        onTap: onTap,
      );
    }

    testWidgets('shows income with a plus', (tester) async {
      await tester.pumpWidget(_host(row(const Money(10440000, Currency.rub))));

      expect(find.text('+104,400.00 ₽'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('20 days'), findsOneWidget);
    });

    testWidgets('shows spending with a true minus', (tester) async {
      await tester.pumpWidget(_host(row(const Money(-3450000, Currency.rub))));

      expect(find.text('−34,500.00 ₽'), findsOneWidget);
    });

    testWidgets('colours income and spending differently', (tester) async {
      await tester.pumpWidget(_host(row(const Money(100, Currency.rub))));
      final income = tester
          .widget<Text>(find.textContaining('+1.00'))
          .style!
          .color;
      await tester.pumpWidget(_host(row(const Money(-100, Currency.rub))));
      final expense = tester
          .widget<Text>(find.textContaining('1.00'))
          .style!
          .color;

      expect(income, isNot(expense));
    });

    testWidgets('has a chevron and is a button only with an action', (
      tester,
    ) async {
      await tester.pumpWidget(_host(row(const Money(100, Currency.rub))));
      expect(find.byIcon(Icons.chevron_right), findsNothing);

      var taps = 0;
      await tester.pumpWidget(
        _host(row(const Money(100, Currency.rub), onTap: () => taps++)),
      );
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.text('Salary'));
      expect(taps, 1);
    });

    testWidgets('is at least 48 dp tall', (tester) async {
      await tester.pumpWidget(
        _host(row(const Money(100, Currency.rub), onTap: () {})),
      );

      expect(
        tester.getSize(find.byType(AmountRow)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('lets a long amount wrap instead of cutting it', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(200, 400);
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: row(const Money(123456789012, Currency.rub)),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('PartSelector', () {
    testWidgets('shows the three options and reports the choice', (
      tester,
    ) async {
      PeriodScope? chosen;
      await tester.pumpWidget(
        _host(
          PartSelector(
            selected: PeriodScope.month,
            onSelected: (scope) => chosen = scope,
          ),
        ),
      );

      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Part 1'), findsOneWidget);
      expect(find.text('Part 2'), findsOneWidget);

      await tester.tap(find.text('Part 2'));

      expect(chosen, PeriodScope.secondPart);
    });
  });

  group('badges', () {
    testWidgets('direction badges have an icon and a label', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              DirectionBadge(DebtDirection.lent),
              DirectionBadge(DebtDirection.borrowed),
            ],
          ),
        ),
      );

      expect(find.text('Lent'), findsOneWidget);
      expect(find.text('Borrowed'), findsOneWidget);
      expect(find.byIcon(Icons.call_made), findsOneWidget);
      expect(find.byIcon(Icons.call_received), findsOneWidget);
    });

    testWidgets('status badges have an icon and a label', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              for (final status in DebtStatus.values) StatusBadge(status),
            ],
          ),
        ),
      );

      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Settled'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('are translated into Arabic', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              DirectionBadge(DebtDirection.lent),
              StatusBadge(DebtStatus.overdue),
            ],
          ),
          locale: const Locale('ar'),
        ),
      );

      expect(find.text('أقرضت'), findsOneWidget);
      expect(find.text('متأخر'), findsOneWidget);
    });
  });
}
