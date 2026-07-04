import 'package:flutter_test/flutter_test.dart';
import 'package:ppn_great/app.dart';

void main() {
  testWidgets('PPNGreatApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PPNGreatApp());
    // Verify the app renders the login screen
    expect(find.text('PPN GREAT'), findsWidgets);
  });
}
