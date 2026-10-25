import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/code_boxes.dart';
import 'package:money_scribe/core/widgets/flow_page.dart';
import 'package:money_scribe/core/widgets/linked_text.dart';
import 'package:money_scribe/core/widgets/pin_pad.dart';
import 'package:money_scribe/core/widgets/state_view.dart';

Widget _host(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  group('CodeBoxes', () {
    late TextEditingController controller;
    late FocusNode focus;

    setUp(() {
      controller = TextEditingController();
      focus = FocusNode();
    });

    tearDown(() {
      controller.dispose();
      focus.dispose();
    });

    Future<void> pumpBoxes(
      WidgetTester tester, {
      bool hasError = false,
      bool enabled = true,
      int length = 6,
    }) {
      return tester.pumpWidget(
        _host(
          Scaffold(
            body: CodeBoxes(
              length: length,
              controller: controller,
              focusNode: focus,
              semanticLabel: 'Code',
              hasError: hasError,
              enabled: enabled,
            ),
          ),
        ),
      );
    }

    testWidgets('shows the typed digits in the boxes', (tester) async {
      await pumpBoxes(tester);

      await tester.enterText(find.byType(TextField), '48');
      await tester.pump();

      expect(find.text('4'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('takes at most as many digits as the code has', (tester) async {
      await pumpBoxes(tester);

      await tester.enterText(find.byType(TextField), '12345678');

      expect(controller.text, '123456');
    });

    testWidgets('a short code takes fewer digits', (tester) async {
      await pumpBoxes(tester, length: 4);

      await tester.enterText(find.byType(TextField), '123456');

      expect(controller.text, '1234');
    });

    testWidgets('six boxes fit a narrow phone at a large text size', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: CodeBoxes(
                  length: 6,
                  controller: controller,
                  focusNode: focus,
                  semanticLabel: 'Code',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '482915');
      await tester.pump();

      expect(tester.takeException(), isNull);
      for (final digit in ['4', '8', '2', '9', '1', '5']) {
        expect(find.text(digit), findsOneWidget);
      }
    });

    testWidgets('keeps only digits, and Western ones', (tester) async {
      await pumpBoxes(tester);

      await tester.enterText(find.byType(TextField), '٤a٨');

      expect(controller.text, '48');
    });

    testWidgets('keeps left-to-right order in a right-to-left screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: CodeBoxes(
              length: 6,
              controller: controller,
              focusNode: focus,
              semanticLabel: 'Code',
            ),
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.enterText(find.byType(TextField), '48');
      await tester.pump();

      expect(
        tester.getCenter(find.text('4')).dx,
        lessThan(tester.getCenter(find.text('8')).dx),
      );
    });

    testWidgets('is read as one labelled text field', (tester) async {
      await pumpBoxes(tester);

      expect(find.bySemanticsLabel('Code'), findsOneWidget);
    });

    testWidgets('cannot be typed in when disabled', (tester) async {
      await pumpBoxes(tester, enabled: false);

      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });
  });

  group('PinPad', () {
    testWidgets('sends the digits and backspace, in a 3 x 4 grid', (
      tester,
    ) async {
      final digits = <int>[];
      var backspaces = 0;
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: PinPad(
              onDigit: digits.add,
              onBackspace: () => backspaces++,
              backspaceLabel: 'Delete',
            ),
          ),
        ),
      );

      for (var digit = 0; digit <= 9; digit++) {
        await tester.tap(find.text('$digit'));
      }
      await tester.tap(find.byIcon(Icons.backspace_outlined));

      expect(digits, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
      expect(backspaces, 1);
      expect(
        tester.getCenter(find.text('1')).dx,
        lessThan(tester.getCenter(find.text('3')).dx),
      );
      expect(
        tester.getCenter(find.text('1')).dy,
        lessThan(tester.getCenter(find.text('7')).dy),
      );
    });

    testWidgets('keys are at least 48 dp', (tester) async {
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: PinPad(
              onDigit: (_) {},
              onBackspace: () {},
              backspaceLabel: 'Delete',
            ),
          ),
        ),
      );

      final size = tester.getSize(
        find.ancestor(of: find.text('5'), matching: find.byType(InkWell)),
      );

      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('does nothing when disabled', (tester) async {
      final digits = <int>[];
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: PinPad(
              enabled: false,
              onDigit: digits.add,
              onBackspace: () {},
              backspaceLabel: 'Delete',
            ),
          ),
        ),
      );

      await tester.tap(find.text('5'));

      expect(digits, isEmpty);
    });
  });

  testWidgets('PinDots fills as many dots as digits were typed', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const Scaffold(body: PinDots(filled: 2))));

    final dots = tester
        .widgetList<Container>(find.byType(Container))
        .map((container) => (container.decoration! as BoxDecoration).color)
        .toList();

    expect(dots.where((color) => color != Colors.transparent), hasLength(2));
    expect(dots, hasLength(4));
  });

  group('LinkedText', () {
    testWidgets('puts the links where the message wants them', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: LinkedText(
              message: (links) => 'Agree to ${links[0]} and ${links[1]}.',
              links: [
                TextLink('Terms', onTap: () => tapped++),
                const TextLink('Privacy'),
              ],
            ),
          ),
        ),
      );

      expect(
        find.text('Agree to Terms and Privacy.', findRichText: true),
        findsOneWidget,
      );

      await tester.tapOnText(find.textRange.ofSubstring('Terms'));
      expect(tapped, 1);
    });

    testWidgets('a link without an action is styled but does nothing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: LinkedText(
              message: (links) => 'See ${links[0]}',
              links: const [TextLink('Privacy')],
            ),
          ),
        ),
      );

      await tester.tapOnText(find.textRange.ofSubstring('Privacy'));

      expect(tester.takeException(), isNull);
    });
  });

  group('FailureView', () {
    testWidgets('No connection offers Try again', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: FailureView(
              kind: FailureKind.noConnection,
              onRetry: () => retried++,
            ),
          ),
        ),
      );

      expect(find.text('No connection'), findsOneWidget);
      expect(
        find.text('Check your internet connection and try again.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Try again'));
      expect(retried, 1);
    });

    testWidgets('an error offers Try again', (tester) async {
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: FailureView(kind: FailureKind.error, onRetry: () {}),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Please try again in a moment.'), findsOneWidget);
    });
  });

  group('FlowPage', () {
    testWidgets('keeps the form behind a failure view', (tester) async {
      final controller = TextEditingController(text: 'typed');
      addTearDown(controller.dispose);
      Widget page(FailureKind? failure) {
        return _host(
          FlowPage(
            failure: failure,
            onRetry: () {},
            content: [TextField(controller: controller)],
          ),
        );
      }

      await tester.pumpWidget(page(null));
      await tester.pumpWidget(page(FailureKind.error));

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);

      await tester.pumpWidget(page(null));

      expect(controller.text, 'typed');
      expect(find.byType(TextField), findsOneWidget);
    });

    group('the brand panel', () {
      Future<void> pump(WidgetTester tester, Size size, {bool panel = true}) {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = size;
        addTearDown(tester.view.reset);
        return tester.pumpWidget(
          _host(
            FlowPage(brandPanelWhenWide: panel, content: const [Text('form')]),
          ),
        );
      }

      testWidgets('shows the name and the tagline beside a wide page', (
        tester,
      ) async {
        await pump(tester, const Size(1280, 800));

        expect(find.text('Money Scribe'), findsOneWidget);
        expect(
          find.text('Your salary, purchases and debts in one place.'),
          findsOneWidget,
        );
        // The form is in the right half.
        expect(
          tester.getCenter(find.text('form')).dx,
          greaterThan(tester.getCenter(find.text('Money Scribe')).dx),
        );
      });

      testWidgets('is not shown on a phone', (tester) async {
        await pump(tester, const Size(412, 915));

        expect(find.text('Money Scribe'), findsNothing);
        expect(find.text('form'), findsOneWidget);
      });

      testWidgets('is not shown when the page turns it off', (tester) async {
        await pump(tester, const Size(1280, 800), panel: false);

        expect(find.text('Money Scribe'), findsNothing);
      });

      testWidgets('mirrors in Arabic: the panel is on the right', (
        tester,
      ) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = const Size(1280, 800);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _host(
            const FlowPage(content: [Text('form')]),
            locale: const Locale('ar'),
          ),
        );

        expect(
          tester.getCenter(find.text('Money Scribe')).dx,
          greaterThan(tester.getCenter(find.text('form')).dx),
        );
      });
    });

    testWidgets('pins the bottom group to the bottom of a tall screen', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(400, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _host(
          const FlowPage(
            content: [Text('top')],
            bottomChildren: [Text('bottom')],
          ),
        ),
      );

      expect(tester.getTopLeft(find.text('top')).dy, lessThan(120));
      expect(tester.getBottomLeft(find.text('bottom')).dy, greaterThan(850));
    });

    testWidgets('scrolls instead of overflowing on a short screen', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(400, 200);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _host(
          FlowPage(
            content: [for (var i = 0; i < 10; i++) const SizedBox(height: 60)],
            bottomChildren: const [Text('bottom')],
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -800),
      );
      await tester.pump();

      expect(find.text('bottom'), findsOneWidget);
    });

    testWidgets('centres its content in the free room', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(400, 800);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _host(
          const FlowPage(
            showBackButton: false,
            centered: true,
            content: [Text('middle')],
          ),
        ),
      );

      expect(tester.getCenter(find.text('middle')).dy, closeTo(400, 30));
    });
  });
}
