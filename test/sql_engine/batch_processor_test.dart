import 'package:flutter_test/flutter_test.dart';
import 'package:sql_student_studio/sql_engine/lexer/batch_processor.dart';

void main() {
  group('BatchProcessor with lexer-aware GO handling', () {
    late BatchProcessor processor;

    setUp(() {
      processor = BatchProcessor();
    });

    test('splits mixed-case isolated GO lines', () {
      const script = '''
CREATE DATABASE University;
go
USE University;
Go
CREATE TABLE Students (ID INT);
GO
''';

      final batches = processor.process(script);

      expect(batches, [
        'CREATE DATABASE University;',
        'USE University;',
        'CREATE TABLE Students (ID INT);',
      ]);
    });

    test('ignores GO in strings, escaped quotes, and multiline literals', () {
      const script = '''
SELECT 'It''s GO time';
SELECT 'first line
GO
last line';
GO
SELECT 3;
''';

      final batches = processor.process(script);

      expect(batches, hasLength(2));
      expect(batches[0], contains("It''s GO time"));
      expect(batches[0], contains('GO\nlast line'));
      expect(batches[1], 'SELECT 3;');
    });

    test('ignores GO in line comments and nested block comments', () {
      const script = '''
SELECT 1;
-- GO
/* outer
   /* nested
      GO
   */
*/
SELECT 2;
GO
SELECT 3;
''';

      final batches = processor.process(script);

      expect(batches, hasLength(2));
      expect(batches[0], contains('-- GO'));
      expect(batches[0], contains('SELECT 2;'));
      expect(batches[1], 'SELECT 3;');
    });

    test('quoted and bracketed GO identifiers are not batch separators', () {
      const script = '''
SELECT [GO], "GO";
GO
SELECT 2;
''';

      final batches = processor.process(script);

      expect(batches, hasLength(2));
      expect(batches[0], contains('[GO]'));
      expect(batches[0], contains('"GO"'));
    });

    test('allows SQLCMD comments after an isolated GO separator', () {
      const script = 'SELECT 1;\r\n  GO -- repeat batch boundary\r\nSELECT 2;';
      final batches = processor.process(script);
      expect(batches, ['SELECT 1;', 'SELECT 2;']);
    });

    test('supports a positive GO repeat count as metadata', () {
      const script = '''
PRINT 'repeat';
GO 3
SELECT 4;
GO
''';

      final batches = processor.processBatches(script);

      expect(batches, hasLength(2));
      expect(batches[0].repeatCount, 3);
      expect(batches[1].repeatCount, 1);
      expect(batches[0].batchNumber, 1);
      expect(batches[1].batchNumber, 2);
    });

    test('reports invalid GO repeat syntax with source position', () {
      for (final script in ['GO 0', 'GO -1', 'GO 2.5', 'GO 2 extra']) {
        expect(
          () => processor.processBatches(script),
          throwsA(
            isA<SqlBatchException>()
                .having((e) => e.code, 'code', 'SSS-BATCH-GO')
                .having((e) => e.line, 'line', 1)
                .having((e) => e.column, 'column', 1),
          ),
          reason: script,
        );
      }
    });

    test('keeps absolute source locations and batch numbers on tokens', () {
      const script = 'SELECT 1;\r\nGO\r\nSELECT 2;';
      final batches = processor.processBatches(script);

      final secondSelect = batches[1].tokens.first;
      expect(secondSelect.lexeme.toUpperCase(), 'SELECT');
      expect(secondSelect.batchNumber, 2);
      expect(secondSelect.startLine, 3);
      expect(secondSelect.startOffset, script.lastIndexOf('SELECT'));
    });

    test('handles empty batches, CRLF, and trailing GO at EOF', () {
      const script = 'GO\r\nGO\r\nSELECT 1;\r\nGO';
      final batches = processor.process(script);

      expect(batches, ['SELECT 1;']);
    });
  });
}
