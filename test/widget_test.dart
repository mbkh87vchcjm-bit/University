import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tabeeb_ashiah/main.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('Tabeeb Ashiah app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TabeebAshiahApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('طبيب أشعة'), findsWidgets);
  });
}
