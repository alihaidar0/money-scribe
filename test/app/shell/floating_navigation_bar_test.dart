import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/app/shell/floating_navigation_bar.dart';

const _labels = ['Overview', 'Salary', 'Transactions', 'Debts', 'Reports'];

final List<NavigationItem> _items = [
  for (final label in _labels)
    NavigationItem(
      icon: LucideIcons.circle,
      selectedIcon: LucideIcons.circleDot,
      label: label,
    ),
];

class _Host extends StatefulWidget {
  const new({this.textDirection = TextDirection.ltr});

  final TextDirection textDirection;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.textDirection,
      child: Scaffold(
        bottomNavigationBar: FloatingNavigationBar(
          selectedIndex: _selected,
          items: _items,
          onSelected: (index) => setState(() => _selected = index),
        ),
      ),
    );
  }
}

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(412, 800),
  double textScale = 1,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: _Host(textDirection: textDirection),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _tab(String label) => find.byTooltip(label);

/// The rounded surface of the bar, without the padding that floats it.
Finder _barSurface() => find
    .descendant(
      of: find.byType(FloatingNavigationBar),
      matching: find.byType(Material),
    )
    .first;

Finder _labelInBar(String label) => find.descendant(
  of: find.byType(FloatingNavigationBar),
  matching: find.text(label),
);

void main() {
  group('labels', () {
    testWidgets('only the selected destination shows its label', (
      tester,
    ) async {
      await _pump(tester);

      expect(_labelInBar('Overview'), findsOneWidget);
      for (final label in _labels.skip(1)) {
        expect(_labelInBar(label), findsNothing, reason: label);
      }
    });

    testWidgets('selecting a destination moves the label to it', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(_tab('Transactions'));
      await tester.pumpAndSettle();

      expect(_labelInBar('Transactions'), findsOneWidget);
      expect(_labelInBar('Overview'), findsNothing);
    });

    testWidgets('the longest label stays on one line inside the bar', (
      tester,
    ) async {
      await _pump(tester, size: const Size(360, 800));
      await tester.tap(_tab('Transactions'));
      await tester.pumpAndSettle();

      final label = tester.getRect(_labelInBar('Transactions'));
      final bar = tester.getRect(find.byType(FloatingNavigationBar));

      expect(label.height, lessThan(24));
      expect(bar.contains(label.topLeft), isTrue);
      expect(bar.contains(label.bottomRight), isTrue);
    });
  });

  group('touch and accessibility', () {
    testWidgets('every destination is at least 48 dp wide and tall', (
      tester,
    ) async {
      await _pump(tester, size: const Size(360, 800));

      for (final label in _labels) {
        final size = tester.getSize(_tab(label));
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
      }
    });

    testWidgets(
      'every destination is a labelled button, one of them selected',
      (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(tester);

        for (final label in _labels) {
          expect(
            tester.getSemantics(find.bySemanticsLabel(label)),
            isSemantics(
              label: label,
              isButton: true,
              hasTapAction: true,
              hasSelectedState: true,
              isSelected: label == 'Overview',
            ),
            reason: label,
          );
        }
        handle.dispose();
      },
    );
  });

  group('layout', () {
    testWidgets('fits a narrow phone with large text', (tester) async {
      await _pump(tester, size: const Size(320, 640), textScale: 2);
      await tester.tap(_tab('Transactions'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_labelInBar('Transactions'), findsOneWidget);
    });

    testWidgets('stays a bar of at most 400 dp on a wide screen', (
      tester,
    ) async {
      await _pump(tester, size: const Size(700, 900));

      final bar = tester.getRect(_barSurface());

      expect(bar.width, lessThanOrEqualTo(FloatingNavigationBar.maxWidth));
      expect(bar.center.dx, closeTo(350, 1));
    });

    testWidgets('floats above the bottom edge of the screen', (tester) async {
      await _pump(tester);

      final bar = tester.getRect(_barSurface());

      expect(bar.bottom, lessThan(800));
      expect(bar.left, greaterThan(0));
    });

    testWidgets('mirrors in Arabic: the first destination is on the right', (
      tester,
    ) async {
      await _pump(tester, textDirection: TextDirection.rtl);

      expect(
        tester.getCenter(_tab('Overview')).dx,
        greaterThan(tester.getCenter(_tab('Reports')).dx),
      );
    });
  });

  testWidgets('tapping a destination reports its index', (tester) async {
    var tapped = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FloatingNavigationBar(
            selectedIndex: 0,
            items: _items,
            onSelected: (index) => tapped = index,
          ),
        ),
      ),
    );

    await tester.tap(_tab('Debts'));

    expect(tapped, 3);
  });
}
