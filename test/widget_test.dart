import 'package:flutter_test/flutter_test.dart';
import 'package:lamon/main.dart';

void main() {
  testWidgets('LamonApp smoke test - verifies Login screen displays', (WidgetTester tester) async {
    await tester.pumpWidget(const LamonApp());
    await tester.pumpAndSettle();

    // Verify that LAMON header and Welcome card exist
    expect(find.text('LAMON'), findsOneWidget);
    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
