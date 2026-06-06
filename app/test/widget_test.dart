// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';

import 'package:alamati_app/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AlamatiApp());

    // Verify that the app loads
    expect(find.text('3alamati'), findsAny);
  });
}
