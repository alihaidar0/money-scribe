import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/main.dart';

void main() {
  testWidgets('the app starts and shows its first screen', (tester) async {
    await tester.pumpWidget(const MainApp());

    expect(find.text('Hello World!'), findsOneWidget);
  });
}
