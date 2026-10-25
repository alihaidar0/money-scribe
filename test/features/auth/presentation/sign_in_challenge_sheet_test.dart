import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/features/auth/presentation/sign_in_challenge_sheet.dart';

import '../../../support/fake_challenge_view_factory.dart';

void main() {
  late FakeChallengeViewFactory factory;
  String? result;
  var closed = false;

  Future<void> open(
    WidgetTester tester, {
    bool rejected = false,
    FakeChallengeViewFactory? custom,
  }) async {
    factory = custom ?? FakeChallengeViewFactory();
    result = null;
    closed = false;
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await showSignInChallengeSheet(
                context,
                factory: factory,
                rejected: rejected,
              );
              closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the challenge under the title', (tester) async {
    await open(tester);

    expect(find.text('Security check'), findsOneWidget);
    expect(find.text('Complete the check to sign in.'), findsOneWidget);
    expect(find.byKey(const Key('fake-challenge')), findsOneWidget);
    expect(find.text('The check did not work. Try again.'), findsNothing);
  });

  testWidgets('closes with the token when the challenge is solved', (
    tester,
  ) async {
    await open(tester);

    factory.solve('the-token');
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, 'the-token');
  });

  testWidgets('a second solution does not close or send anything again', (
    tester,
  ) async {
    await open(tester);

    factory
      ..solve('first')
      ..solve('second');
    await tester.pumpAndSettle();

    expect(result, 'first');
  });

  testWidgets('says the last token was refused', (tester) async {
    await open(tester, rejected: true);

    expect(find.text('The check did not work. Try again.'), findsOneWidget);
    expect(find.byKey(const Key('fake-challenge')), findsOneWidget);
  });

  testWidgets('Cancel closes it with nothing', (tester) async {
    await open(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('a failed challenge offers Try again and builds a new one', (
    tester,
  ) async {
    await open(tester);
    expect(factory.built, hasLength(1));

    factory.fail();
    await tester.pumpAndSettle();

    expect(
      find.text(
        'The check could not load. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('fake-challenge')), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fake-challenge')), findsOneWidget);
    expect(factory.built, hasLength(2));
    expect(factory.built.first, isNot(factory.built.last));
  });

  testWidgets('says so when this build cannot show the challenge', (
    tester,
  ) async {
    await open(tester, custom: FakeChallengeViewFactory(isAvailable: false));

    expect(
      find.text(
        'The security check is not available right now. Try again later.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('fake-challenge')), findsNothing);
    expect(factory.built, isEmpty);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
