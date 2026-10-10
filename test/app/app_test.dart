import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/app.dart';
import 'package:money_scribe/features/overview/presentation/overview_screen.dart';

void main() {
  testWidgets('the app starts on the overview screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoneyScribeApp()));

    expect(find.byType(OverviewScreen), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
  });
}
