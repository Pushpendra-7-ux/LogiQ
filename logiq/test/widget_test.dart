import 'package:flutter_test/flutter_test.dart';
import 'package:logiq/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LogiQApp());
    await tester.pump(const Duration(milliseconds: 2000));
    expect(find.byType(LogiQApp), findsOneWidget);
  });
}
