import 'package:flutter_test/flutter_test.dart';
import 'package:sql_student_studio/sql_engine/lexer/batch_processor.dart';

void main() {
  group('BatchProcessor Edge-Case Tests', () {
    late BatchProcessor processor;

    setUp(() {
      processor = BatchProcessor();
    });

    test('splits script by mixed case GO separators', () {
      const script = '''
CREATE DATABASE University;
go
USE University;
Go
CREATE TABLE Students (ID INT);
GO
''';

      final batches = processor.process(script);

      expect(batches.length, equals(3));
      expect(batches[0], equals('CREATE DATABASE University;'));
      expect(batches[1], equals('USE University;'));
      expect(batches[2], equals('CREATE TABLE Students (ID INT);'));
    });

    test('handles empty batches and consecutive GOs without error', () {
      const script = '''
GO
GO
SELECT 1;
GO
GO
''';

      final batches = processor.process(script);

      expect(batches.length, equals(1));
      expect(batches[0], equals('SELECT 1;'));
    });

    test('ignores GO inside single-quote string literal with escaped quotes', () {
      const script = '''
SELECT 'It''s GO time' AS TestCol;
GO
SELECT * FROM Students;
''';

      final batches = processor.process(script);

      expect(batches.length, equals(2));
      expect(batches[0], contains("'It''s GO time'"));
      expect(batches[1], equals('SELECT * FROM Students;'));
    });

    test('ignores GO inside line comments and block comments', () {
      const script = '''
SELECT 1;
-- GO
/*
GO
*/
SELECT 2;
GO
''';

      final batches = processor.process(script);

      expect(batches.length, equals(1));
      expect(batches[0], contains('SELECT 1;'));
      expect(batches[0], contains('-- GO'));
      expect(batches[0], contains('SELECT 2;'));
    });

    test('handles CRLF line endings and trailing GO at EOF', () {
      const script = "SELECT 1;\r\nGO\r\nSELECT 2;\r\nGO";

      final batches = processor.process(script);

      expect(batches.length, equals(2));
      expect(batches[0], equals('SELECT 1;'));
      expect(batches[1], equals('SELECT 2;'));
    });
  });
}
