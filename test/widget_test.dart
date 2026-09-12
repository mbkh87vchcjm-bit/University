import 'package:flutter_test/flutter_test.dart';
import 'package:sql_student_studio/app/app.dart';

void main() {
  testWidgets('App renders Home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SqlStudentStudioApp());
    expect(find.text('SQL Student Studio'), findsWidgets);
  });
}
