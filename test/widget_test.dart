import 'package:flutter_test/flutter_test.dart';
import 'package:tabeeb_ashiah/main.dart';

void main() {
  testWidgets('Tabeeb Ashiah app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TabeebAshiahApp());
    expect(find.text('طبيب أشعة'), findsWidgets);
  });
}
