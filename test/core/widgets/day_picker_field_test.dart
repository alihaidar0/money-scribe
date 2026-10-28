import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/theme/app_theme.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/day_picker_field.dart';

/// A host that keeps the day the field reports, like a form does.
class _Host extends StatefulWidget {
  const new({
    this.initial = 20,
    this.max = 31,
    this.captionFor,
    this.onChanged,
  });

  final int initial;
  final int max;
  final String Function(int day)? captionFor;
  final ValueChanged<int>? onChanged;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late int _day = widget.initial;

  @override
  Widget build(BuildContext context) {
    return DayPickerField(
      label: 'Day of the month',
      value: _day,
      min: 1,
      max: widget.max,
      captionFor: widget.captionFor,
      onChanged: (day) {
        widget.onChanged?.call(day);
        setState(() => _day = day);
      },
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(412, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byType(DayPickerField));
  await tester.pumpAndSettle();
}

/// Turns the wheel by [days] days (a negative number goes back).
Future<void> _turn(WidgetTester tester, int days) async {
  await tester.drag(find.byType(ListWheelScrollView), Offset(0, -48.0 * days));
  await tester.pumpAndSettle();
}

Finder _done() => find.widgetWithText(FilledButton, 'Done');

void main() {
  group('DayPickerField', () {
    testWidgets('shows the label and the day', (tester) async {
      await _pump(tester, const _Host());

      expect(find.text('Day of the month'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.byType(ListWheelScrollView), findsNothing);
    });

    testWidgets('opens a wheel on the day, with Cancel and Done', (
      tester,
    ) async {
      await _pump(tester, const _Host());

      await _open(tester);

      expect(find.byType(ListWheelScrollView), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      // The title of the sheet and the label of the field.
      expect(find.text('Day of the month'), findsNWidgets(2));
      expect(find.text('Cancel'), findsOneWidget);
      expect(_done(), findsOneWidget);
    });

    testWidgets('Done gives the day the wheel stopped on', (tester) async {
      final reported = <int>[];
      await _pump(tester, _Host(onChanged: reported.add));
      await _open(tester);

      await _turn(tester, -7);
      await tester.tap(_done());
      await tester.pumpAndSettle();

      expect(reported, [13]);
      expect(find.text('13'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('Cancel and dismissing keep the day', (tester) async {
      final reported = <int>[];
      await _pump(tester, _Host(onChanged: reported.add));

      await _open(tester);
      await _turn(tester, -7);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await _open(tester);
      await _turn(tester, 4);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(reported, isEmpty);
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('a tap on a day turns the wheel to it', (tester) async {
      final reported = <int>[];
      await _pump(tester, _Host(onChanged: reported.add));
      await _open(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(ListWheelScrollView),
          matching: find.text('22'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(_done());
      await tester.pumpAndSettle();

      expect(reported, [22]);
    });

    testWidgets('only offers the days of the month', (tester) async {
      final reported = <int>[];
      await _pump(tester, _Host(initial: 28, max: 28, onChanged: reported.add));
      await _open(tester);

      // Past the last day of a short month the wheel stays on the last one.
      await _turn(tester, 5);
      await tester.tap(_done());
      await tester.pumpAndSettle();

      expect(reported, [28]);
    });

    testWidgets('says something about the day under the wheel', (tester) async {
      await _pump(
        tester,
        _Host(captionFor: (day) => day >= 20 ? 'late $day' : 'early $day'),
      );
      await _open(tester);

      expect(find.text('late 20'), findsOneWidget);

      await _turn(tester, -7);

      expect(find.text('early 13'), findsOneWidget);
      expect(find.text('late 20'), findsNothing);
    });

    testWidgets('keeps its figures Western in Arabic', (tester) async {
      await _pump(tester, const _Host(), locale: const Locale('ar'));
      await _open(tester);

      expect(find.text('20'), findsWidgets);
      expect(find.text('٢٠'), findsNothing);
    });

    testWidgets('is a button with its day as the value, and the wheel can be '
        'turned by a screen reader', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const _Host());

      expect(
        tester.getSemantics(find.byType(DayPickerField)),
        isSemantics(
          label: 'Day of the month',
          value: '20',
          isButton: true,
          hasTapAction: true,
        ),
      );

      await _open(tester);
      final wheel = find.bySemanticsLabel('Day of the month').last;
      expect(
        tester.getSemantics(wheel),
        isSemantics(
          label: 'Day of the month',
          value: '20',
          increasedValue: '21',
          decreasedValue: '19',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('fits large text and a small screen', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(320, 480);
      addTearDown(tester.view.reset);
      await _pump(tester, const _Host(), textScale: 2);
      tester.view.physicalSize = const Size(320, 480);

      await _open(tester);

      expect(tester.takeException(), isNull);
      expect(_done(), findsOneWidget);
    });
  });
}
