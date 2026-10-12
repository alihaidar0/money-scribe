import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/widgets/two_columns.dart';
import 'package:money_scribe/core/widgets/wide_frame.dart';

Widget _host(Widget child) => MaterialApp(home: child);

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
}

void main() {
  group('WideFrame', () {
    testWidgets('changes nothing on a phone', (tester) async {
      await _size(tester, const Size(412, 915));
      await tester.pumpWidget(
        _host(const WideFrame(child: Scaffold(body: Text('page')))),
      );

      expect(find.byType(DecoratedBox), findsNothing);
      expect(tester.getSize(find.byType(Scaffold)), const Size(412, 915));
    });

    testWidgets('is one centred column of the chosen width on a wide window', (
      tester,
    ) async {
      await _size(tester, const Size(1280, 800));
      await tester.pumpWidget(
        _host(
          const WideFrame(
            width: FrameWidth.narrow,
            child: Scaffold(body: Text('page')),
          ),
        ),
      );

      final scaffold = tester.getRect(find.byType(Scaffold));
      expect(scaffold.width, FrameWidth.narrow.value);
      expect(scaffold.center.dx, 640);
      expect(scaffold.height, 800);
    });

    testWidgets('each width is wider than the one before', (tester) async {
      expect(FrameWidth.narrow.value, lessThan(FrameWidth.regular.value));
      expect(FrameWidth.regular.value, lessThan(FrameWidth.wide.value));
    });

    testWidgets('is as wide as the window when the window is narrower', (
      tester,
    ) async {
      await _size(tester, const Size(640, 800));
      await tester.pumpWidget(
        _host(const WideFrame(child: Scaffold(body: Text('page')))),
      );

      expect(tester.getSize(find.byType(Scaffold)).width, 640);
    });

    testWidgets('tells its child the width of the column', (tester) async {
      await _size(tester, const Size(1280, 800));
      late Size seen;
      await tester.pumpWidget(
        _host(
          WideFrame(
            child: Builder(
              builder: (context) {
                seen = MediaQuery.sizeOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(seen, Size(FrameWidth.regular.value, 800));
    });
  });

  group('TwoColumns', () {
    Widget columns() {
      return const SingleChildScrollView(
        child: TwoColumns(first: [Text('one')], second: [Text('two')]),
      );
    }

    testWidgets('puts the blocks side by side when there is room', (
      tester,
    ) async {
      await _size(tester, const Size(1000, 800));
      await tester.pumpWidget(_host(columns()));

      expect(
        tester.getTopLeft(find.text('one')).dy,
        tester.getTopLeft(find.text('two')).dy,
      );
      expect(
        tester.getTopLeft(find.text('one')).dx,
        lessThan(tester.getTopLeft(find.text('two')).dx),
      );
    });

    testWidgets('stacks them on a narrow window', (tester) async {
      await _size(tester, const Size(412, 800));
      await tester.pumpWidget(_host(columns()));

      expect(
        tester.getTopLeft(find.text('one')).dy,
        lessThan(tester.getTopLeft(find.text('two')).dy),
      );
    });

    testWidgets('gives the whole width to the block that is not empty', (
      tester,
    ) async {
      await _size(tester, const Size(1000, 800));
      await tester.pumpWidget(
        _host(const TwoColumns(first: [Text('only')], second: [])),
      );

      expect(find.text('only'), findsOneWidget);
    });
  });
}
