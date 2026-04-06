import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kolirus/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: KolirusApp()));

    // Verify that the logo/title 'Kolirus' is displayed in the header
    expect(find.text('Kolirus'), findsOneWidget);

    // Verify that the navigation bar exists
    expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
  });
}