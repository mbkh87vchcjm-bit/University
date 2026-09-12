import 'package:flutter_test/flutter_test.dart';
import 'package:sql_student_studio/sql_engine/lexer/batch_processor.dart';

void main() {
  group('BatchProcessor Tests', () {
    late BatchProcessor processor;

    setUp(() {
      processor = BatchProcessor();
    });

    test('splits script by GO separator', () {
      const script = '''
CREATE DATABASE University;
GO
USE University;
GO
CREATE TABLE Students (ID INT);
GO
''';

      final batches = processor.process(script);

      expect(batches.length, equals(3));
      expect(batches[0], equals('CREATE DATABASE University;'));
      expect(batches[1], equals('USE University;'));
      expect(batches[2], equals('CREATE TABLE Students (ID INT);'));
    });

    test('ignores GO inside string literal', () {
      const script = '''
SELECT 'GO' AS LiteralText;
GO
SELECT * FROM Students;
''';

      final batches = processor.process(script);

      expect(batches.length, equals(2));
      expect(batches[0], contains("'GO'"));
      expect(batches[1], equals('SELECT * FROM Students;'));
    });

    test('ignores GO inside line comment', () {
      const script = '''
SELECT 1;
-- GO
SELECT 2;
GO
SELECT 3;
''';

      final batches = processor.process(script);

      expect(batches.length, equals(2));
      expect(batches[0], contains('SELECT 1;\n-- GO\nSELECT 2;'));
      expect(batches[1], equals('SELECT 3;'));
    });
  });
}
